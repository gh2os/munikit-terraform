locals {
  name_prefix_base = "${var.app_name}-${var.environment}-${var.instance_name}"
  name_prefix_hash = substr(sha1(local.name_prefix_base), 0, 8)
  name_prefix_stem = replace(substr(local.name_prefix_base, 0, 51), "/-+$/", "")
  name_prefix      = length(local.name_prefix_base) <= 60 ? local.name_prefix_base : "${local.name_prefix_stem}-${local.name_prefix_hash}"
  labels = merge(var.labels, {
    app         = var.app_name
    environment = var.environment
    instance    = var.instance_name
  })
  media_bucket_base_name    = "${var.project_id}-${local.name_prefix}-media"
  media_bucket_hash         = sha1(local.media_bucket_base_name)
  default_media_bucket_name = "media-${local.media_bucket_hash}"
  media_bucket_name         = coalesce(var.media_bucket_name, local.default_media_bucket_name)
}

module "networking" {
  source = "../../modules/networking"

  project_id  = var.project_id
  region      = var.region
  name_prefix = local.name_prefix
  labels      = local.labels
}

module "database" {
  source = "../../modules/database"

  project_id                   = var.project_id
  region                       = var.region
  name_prefix                  = local.name_prefix
  instance_name                = local.name_prefix
  database_deletion_protection = false
  labels                       = local.labels
}

module "storage" {
  source = "../../modules/storage"

  project_id      = var.project_id
  name_prefix     = local.name_prefix
  bucket_name     = local.media_bucket_name
  bucket_location = var.bucket_location
  public_media    = true
  labels          = local.labels
}

module "iam" {
  source = "../../modules/iam"

  project_id                           = var.project_id
  name_prefix                          = local.name_prefix
  media_bucket_name                    = module.storage.bucket_name
  runtime_service_account_display_name = "${local.name_prefix} runtime"
  secret_ids = compact([
    module.database.database_url_secret_id,
    module.storage.s3_access_key_id_secret_id,
    module.storage.s3_secret_access_key_secret_id,
  ])
}

module "app" {
  source = "../../modules/munikit-app"

  depends_on = [
    module.database,
    module.iam,
    module.storage,
  ]

  project_id                     = var.project_id
  region                         = var.region
  app_name                       = var.app_name
  environment                    = var.environment
  instance_name                  = var.instance_name
  runtime_service_account_email  = module.iam.runtime_service_account_email
  container_image                = var.container_image
  labels                         = local.labels
  allow_unauthenticated          = true
  cloud_sql_connection_name      = module.database.connection_name
  database_url_secret_id         = module.database.database_url_secret_id
  s3_bucket                      = module.storage.bucket_name
  s3_endpoint                    = module.storage.s3_endpoint
  s3_region                      = module.storage.s3_region
  s3_access_key_id_secret_id     = module.storage.s3_access_key_id_secret_id
  s3_secret_access_key_secret_id = module.storage.s3_secret_access_key_secret_id
  extra_env_vars                 = var.extra_env_vars
}
