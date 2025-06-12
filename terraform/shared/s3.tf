# ========================================================================
# S3 bucket for project data storage (used by all modules)
#
# NOTE:
# - This bucket resource is called "ingestion" for historical reasons.
# - We use it for ALL modules (ingestion, transformation, warehouse_loader).
# - Ideally, we should have named it something generic (e.g. "project_bucket"),
#   because the initial plan was to have one bucket per module, but we ended
#   up using a single bucket for the whole project.
# - To avoid disrupting existing infrastructure and data, we are keeping
#   the name "ingestion" in the code.
#
# If refactoring in the future, rename this resource and all related outputs,
# and update the Terraform state with 'terraform state mv' to avoid resource recreation.
# ========================================================================

resource "aws_s3_bucket" "ingestion" {
  bucket = var.bucket_name != "" ? var.bucket_name : "data-ingestion-bucket"
  lifecycle {
    prevent_destroy = false
  }

# Versioning only affects future changes. If files are deleted or overwritten after enabling versioning, you can recover previous versions.
# Recommended for any S3 used for:
# Terraform state storage
# ETL pipelines (raw, transformed, or results data)
# No data loss: Versioning allows you to rollback or recover files if someone makes a mistake.
  
  versioning {
    enabled = true
  }
}

# Output the bucket name for use in other modules
output "ingestion_bucket" {
  value = aws_s3_bucket.ingestion.bucket
}
