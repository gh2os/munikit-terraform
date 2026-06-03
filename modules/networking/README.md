# networking Module

Reusable module for optional networking infrastructure.

The default architecture uses the Cloud Run Cloud SQL connector and does not need a VPC. This module therefore creates no resources by default.

When private networking is needed, it can create:

- A VPC network.
- A Serverless VPC Access connector for Cloud Run.
