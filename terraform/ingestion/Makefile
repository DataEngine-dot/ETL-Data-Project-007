# 'deploy' will:
# 1. Run 'terraform init' (if not already done)
# 2. Build Lambda code (if not already done)
# 3. Create new ingestion.tfvars
# 4. Run Terraform apply
# Use 'make deploy' only, not the steps separately, unless you know what you are doing.

generate-tfvars:
	@echo "Generating ingestion.tfvars from shared outputs..."
	$(eval S3_BUCKET=$(shell cd ../shared && terraform output -raw ingestion_bucket))
	$(eval SNS_TOPIC=$(shell cd ../shared && terraform output -raw sns_topic))
	$(eval LAMBDA_ROLE_ARN=$(shell cd ../shared && terraform output -raw lambda_role_arn))
	@echo "s3_bucket = \"$(S3_BUCKET)\"" > ingestion.tfvars
	@echo "sns_topic = \"$(SNS_TOPIC)\"" >> ingestion.tfvars
	@echo "lambda_role_arn = \"$(LAMBDA_ROLE_ARN)\"" >> ingestion.tfvars
	@cat ../secrets.tfvars >> ingestion.tfvars
	@echo "Done: ingestion.tfvars created"

init:
	terraform init

build:
	@echo "Packaging ingestion Lambda code with dependencies..."
	rm -rf ../../lambda_build
	mkdir -p ../../lambda_build ../../builds
	pip install -r ../../requirements.txt --target=../../lambda_build
	cp ../../ingestion.py ../../lambda_build/
	cp -r ../../utils ../../lambda_build/
	cd ../../lambda_build && zip -r ../builds/ingestion-lambda.zip .
	@echo "Lambda package created at ../../builds/ingestion-lambda.zip"


plan:
	terraform plan -var-file="ingestion.tfvars"

apply:
	terraform apply -var-file="ingestion.tfvars" -auto-approve

destroy:
	terraform destroy -var-file="ingestion.tfvars" -auto-approve

.PHONY: build init plan apply destroy deploy
