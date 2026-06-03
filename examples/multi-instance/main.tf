locals {
  instance_labels = {
    for name, instance in var.instances : name => merge(var.labels, {
      app         = var.app_name
      environment = var.environment
      instance    = name
    })
  }
}

module "networking" {
  source = "../../modules/networking"

  project_id  = var.project_id
  region      = var.region
  name_prefix = "${var.app_name}-${var.environment}"
  labels      = var.labels
}

module "database" {
  source = "../../modules/database"

  for_each = var.instances

  project_id                   = var.project_id
  region                       = var.region
  name_prefix                  = "${var.app_name}-${var.environment}-${each.key}"
  instance_name                = "${var.app_name}-${var.environment}-${each.key}"
  database_deletion_protection = false
  labels                       = local.instance_labels[each.key]
}

module "storage" {
  source = "../../modules/storage"

  for_each = var.instances

  project_id      = var.project_id
  name_prefix     = "${var.app_name}-${var.environment}-${each.key}"
  bucket_name     = coalesce(each.value.media_bucket_name, "${var.project_id}-${var.app_name}-${var.environment}-${each.key}-media")
  bucket_location = var.bucket_location
  public_media    = true
  labels          = local.instance_labels[each.key]
}

module "iam" {
  source = "../../modules/iam"

  for_each = var.instances

  project_id                           = var.project_id
  name_prefix                          = "${var.app_name}-${var.environment}-${each.key}"
  media_bucket_name                    = module.storage[each.key].bucket_name
  runtime_service_account_display_name = "${var.app_name}-${var.environment}-${each.key} runtime"
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
