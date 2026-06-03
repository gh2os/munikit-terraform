# database Module

Reusable module for Cloud SQL PostgreSQL infrastructure.

This module creates:

- A Cloud SQL PostgreSQL instance.
- An application database and user.
- A generated database password.
- A Secret Manager secret for `DATABASE_URL` using the Cloud SQL Unix socket form.

The generated database password and `DATABASE_URL` are stored in Terraform state. Use a secured remote backend for real environments.
