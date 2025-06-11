# ------------------------------------------------------------
# About this Terraform setup
#
# You can put all modules (ingestion, transformation, warehouse, step_function)
# into this main.tf file and run everything from one place.
#
# In this project, we did NOT do that.
# Instead, each module is in its own folder, with its own backend and Makefile.
#
# Why? Because:
# - It is easier for the team: each person works in their own module
# - No one blocks or breaks the work of others
# - Good for learning and moving fast
#
# If you want, you can put all modules here and manage the whole system together.
# We did not do that for this project.
#
# Look in each module folder for Makefile and instructions.
# ------------------------------------------------------------


module "shared" {
  source      = "./shared"
  bucket_name = var.bucket_name
  alert_email = var.alert_email
}

module "ingestion" {
  source        = "./ingestion"
  db_host       = var.db_host
  db_user       = var.db_user
  db_password   = var.db_password
  s3_bucket     = module.shared.ingestion_bucket
  sns_topic     = module.shared.sns_topic
  lambda_role_arn = module.shared.lambda_role_arn
}

module "step_function" {
  source = "./step_function"
  ingestion_lambda_arn        = module.ingestion.lambda_arn
  transformation_lambda_arn   = module.transformation.lambda_arn
  warehouse_loader_lambda_arn = module.warehouse_loader.lambda_arn
}