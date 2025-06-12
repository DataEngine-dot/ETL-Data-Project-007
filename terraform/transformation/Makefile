# ---------------------------------------------------------------------
# Makefile for Transformation Lambda
# Responsibilities:
# - Package the Lambda code and dependencies into a dedicated build folder
# - Initialize Terraform for this module
# - Plan, apply, or destroy infrastructure changes
# - Deploy Lambda and infra together with a single command
# ---------------------------------------------------------------------

# Generate transformation.tfvars for this module.
# This sets:
# - input_bucket  = bucket for raw (ingested) data (usually the ingestion bucket)
# - output_bucket = bucket for processed data (can be the same as input_bucket, or a different bucket if desired)
# - lambda_role_arn and sns_topic from shared outputs
#
# Note: You can use a different S3 bucket for 'output_bucket' if you want to keep processed data separate.
# By default, both input and output use the ingestion bucket.

generate-tfvars:
	@echo "input_bucket = \"$(shell cd ../shared && terraform output -raw ingestion_bucket)\"" > transformation.tfvars
	@echo "output_bucket = \"$(shell cd ../shared && terraform output -raw ingestion_bucket)\"" >> transformation.tfvars
	@echo "lambda_role_arn = \"$(shell cd ../shared && terraform output -raw lambda_role_arn)\"" >> transformation.tfvars
	@echo "sns_topic = \"$(shell cd ../shared && terraform output -raw sns_topic)\"" >> transformation.tfvars
	@echo "Done: transformation.tfvars created"


build:
	@echo "Packaging transformation Lambda code with dependencies..."
	rm -rf ../../lambda_build_transformation
	mkdir -p ../../lambda_build_transformation ../../builds
	pip install -r ../../requirements.txt --target=../../lambda_build_transformation
	cp ../../transformation.py ../../lambda_build_transformation/
	# If you have utils, include them (optional)
	cp -r ../../utils ../../lambda_build_transformation/ || true
	cd ../../lambda_build_transformation && zip -r ../builds/transformation-lambda.zip .
	@echo "Lambda package created at ../../builds/transformation-lambda.zip"

# Initialize Terraform (backend)
init:
	terraform init

# Show Terraform plan
plan:
	terraform plan -var-file="transformation.tfvars"

# Apply (deploy) infrastructure
apply:
	terraform apply -var-file="transformation.tfvars" -auto-approve

# Destroy all resources in this module
destroy:
	terraform destroy -var-file="transformation.tfvars" -auto-approve

# Deploy: runs everything in order (recommended for most users)
deploy: build init plan apply
	@echo "Transformation module built and deployed."

# ---------------------------------------------------------------------
# .PHONY DECLARATION (best practice for make targets without real files)
# ---------------------------------------------------------------------
.PHONY: build init plan apply destroy deploy
