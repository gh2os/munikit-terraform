locals {
  database_url_secret_id = coalesce(var.database_url_secret_id, "${var.name_prefix}-database-url")
  database_url           = "postgresql://${var.database_user}:${urlencode(random_password.database.result)}@localhost:5432/${var.database_name}?host=/cloudsql/${google_sql_database_instance.this.connection_name}"
}

resource "random_password" "database" {
  length           = var.database_password_length
  special          = true
  override_special = "_-~."
}

resource "google_sql_database_instance" "this" {
  project             = var.project_id
  name                = var.instance_name
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.database_deletion_protection

  settings {
    tier              = var.database_tier
    disk_size         = var.database_disk_size_gb
    disk_type         = var.database_disk_type
    availability_type = var.availability_type
    user_labels       = var.labels

    backup_configuration {
      enabled    = var.database_backup_enabled
      start_time = var.database_backup_start_time
    }

    ip_configuration {
      ipv4_enabled = var.database_ipv4_enabled
    }
  }
}

resource "google_sql_database" "app" {
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = var.database_name
}

resource "google_sql_user" "app" {
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = var.database_user
  password = random_password.database.result
}

resource "google_secret_manager_secret" "database_url" {
  project   = var.project_id
  secret_id = local.database_url_secret_id
  labels    = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "database_url" {
  secret      = google_secret_manager_secret.database_url.id
  secret_data = local.database_url

  depends_on = [
    google_sql_database.app,
    google_sql_user.app,
  ]
}
