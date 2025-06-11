# Simple Makefile for Terraform module
# Each command runs in the current module folder

# 1. Initialize Terraform (set up backend and download plugins)
init:
	terraform init

# 2. Show the Terraform plan (uses main secrets.tfvars for variables)
plan:
	terraform plan -var-file="shared.tfvars"

# 3. Apply changes (create/update infrastructure)
apply:
	terraform apply -var-file="shared.tfvars" -auto-approve

# 4. Destroy resources (removes everything for this module)
destroy:
	terraform destroy -var-file="shared.tfvars" -auto-approve

# 5. Show Terraform outputs
output:
	terraform output

# These are "phony" targets (they are not real files)
.PHONY: init plan apply destroy output