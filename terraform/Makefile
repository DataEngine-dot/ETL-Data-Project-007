init:
	terraform init

plan:
	terraform plan -var-file="secrets.tfvars"

apply:
	terraform apply -var-file="secrets.tfvars" -auto-approve

destroy:
	terraform destroy -var-file="secrets.tfvars" -auto-approve

output:
	terraform output

.PHONY: init plan apply destroy output