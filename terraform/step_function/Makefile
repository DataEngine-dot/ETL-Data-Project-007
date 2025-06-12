# ---------------------------------------------------------------------
# Makefile for Step Function Module
# Responsibilities:
# - Generate .tfvars file dynamically from other module outputs
# - Initialize Terraform
# - Plan, apply, destroy infrastructure
# - Deploy everything with a single command
# ---------------------------------------------------------------------

generate-tfvars:
	@echo "Generating step_function.tfvars from module outputs..."
	$(eval INGESTION_LAMBDA_ARN=$(shell cd ../ingestion && terraform output -raw lambda_arn))
	$(eval TRANSFORMATION_LAMBDA_ARN=$(shell cd ../transformation && terraform output -raw lambda_arn))
	$(eval WAREHOUSE_LOADER_LAMBDA_ARN=$(shell cd ../warehouse_loader && terraform output -raw lambda_arn))
	@echo "ingestion_lambda_arn = \"$(INGESTION_LAMBDA_ARN)\"" > step_function.tfvars
	@echo "transformation_lambda_arn = \"$(TRANSFORMATION_LAMBDA_ARN)\"" >> step_function.tfvars
	@echo "warehouse_loader_lambda_arn = \"$(WAREHOUSE_LOADER_LAMBDA_ARN)\"" >> step_function.tfvars
	@echo "Done: step_function.tfvars created"

init:
	terraform init

plan:
	terraform plan -var-file="step_function.tfvars"

apply:
	terraform apply -var-file="step_function.tfvars" -auto-approve

destroy:
	terraform destroy -var-file="step_function.tfvars" -auto-approve

deploy: generate-tfvars init plan apply
	@echo "Step Function deployed."

.PHONY: generate-tfvars init plan apply destroy deploy