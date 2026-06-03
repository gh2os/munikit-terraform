locals {
  network_name_prefix_base = "${var.app_name}-${var.environment}"
  network_name_prefix_hash = substr(sha1(local.network_name_prefix_base), 0, 8)
  network_name_prefix_stem = replace(substr(local.network_name_prefix_base, 0, 51), "/-+$/", "")
  network_name_prefix      = length(local.network_name_prefix_base) <= 60 ? local.network_name_prefix_base : "${local.network_name_prefix_stem}-${local.network_name_prefix_hash}"

  instance_name_prefix_bases = {
    for name, instance in var.instances : name => "${var.app_name}-${var.environment}-${name}"
  }

  instance_name_prefix_hashes = {
    for name, prefix in local.instance_name_prefix_bases : name => substr(sha1(prefix), 0, 8)
  }

  instance_name_prefix_stems = {
    for name, prefix in local.instance_name_prefix_bases : name => replace(substr(prefix, 0, 51), "/-+$/", "")
  }

  instance_name_prefixes = {
    for name, prefix in local.instance_name_prefix_bases :
    name => length(prefix) <= 60 ? prefix : "${local.instance_name_prefix_stems[name]}-${local.instance_name_prefix_hashes[name]}"
  }

  instance_labels = {
    for name, instance in var.instances : name => merge(var.labels, {
      app         = var.app_name
      environment = var.environment
      instance    = name
    })
  }

  media_bucket_base_names = {
    for name, instance in var.instances : name => "${var.project_id}-${var.app_name}-${var.environment}-${name}-media"
  }

  media_bucket_hashes = {
    for name, bucket_name in local.media_bucket_base_names : name => sha1(bucket_name)
  }

  default_media_bucket_names = {
    for name, bucket_name in local.media_bucket_base_names :
    name => "media-${local.media_bucket_hashes[name]}"
  }
}

module "networking" {
  source = "../../modules/networking"

  project_id  = var.project_id
  region      = var.region
  name_prefix = local.network_name_prefix
  labels      = var.labels
}

module "database" {
  source = "../../modules/database"

  for_each = var.instances

  project_id                   = var.project_id
  region                       = var.region
  name_prefix                  = local.instance_name_prefixes[each.key]
  instance_name                = local.instance_name_prefixes[each.key]
  database_deletion_protection = false
  labels                       = local.instance_labels[each.key]
}

module "storage" {
  source = "../../modules/storage"

  for_each = var.instances

  project_id      = var.project_id
  name_prefix     = local.instance_name_prefixes[each.key]
  bucket_name     = coalesce(each.value.media_bucket_name, local.default_media_bucket_names[each.key])
  bucket_location = var.bucket_location
  public_media    = true
  labels          = local.instance_labels[each.key]
}

module "iam" {
  source = "../../modules/iam"

  for_each = var.instances

  project_id                           = var.project_id
  name_prefix                          = local.instance_name_prefixes[each.key]
  media_bucket_name                    = module.storage[each.key].bucket_name
  runtime_service_account_display_name = "${local.instance_name_prefixes[each.key]} runtime"
  secret_ids = compact([
    module.database[each.key].database_url_secret_id,
    module.storage[each.key].s3_access_key_id_secret_id,
    module.storage[each.key].s3_secret_access_key_secret_id,
  ])
}

module "app" {
  source = "../../modules/munikit-app"

  for_each = var.instances

  depends_on = [
    module.database,
    module.iam,
    module.storage,
  ]

  project_id                     = var.project_id
  region                         = var.region
  app_name                       = var.app_name
  environment                    = var.environment
  instance_name                  = each.key
  runtime_service_account_email  = module.iam[each.key].runtime_service_account_email
  container_image                = each.value.container_image
  labels                         = local.instance_labels[each.key]
  allow_unauthenticated          = each.value.allow_unauthenticated
  cloud_sql_connection_name      = module.database[each.key].connection_name
  database_url_secret_id         = module.database[each.key].database_url_secret_id
  s3_bucket                      = module.storage[each.key].bucket_name
  s3_endpoint                    = module.storage[each.key].s3_endpoint
  s3_region                      = module.storage[each.key].s3_region
  s3_access_key_id_secret_id     = module.storage[each.key].s3_access_key_id_secret_id
  s3_secret_access_key_secret_id = module.storage[each.key].s3_secret_access_key_secret_id
  extra_env_vars                 = each.value.extra_env_vars
}
