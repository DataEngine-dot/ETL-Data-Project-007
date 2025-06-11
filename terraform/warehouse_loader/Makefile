generate-tfvars:
	@echo "Getting bucket name from shared outputs..."
	$(eval S3_BUCKET=$(shell cd ../shared && terraform output -raw ingestion_bucket))
	@echo "s3_bucket = \"$(S3_BUCKET)\"" > warehouse.tfvars
	$(eval LAMBDA_ROLE_ARN=$(shell cd ../shared && terraform output -raw lambda_role_arn))
	@echo "lambda_role_arn = \"$(LAMBDA_ROLE_ARN)\"" >> warehouse.tfvars
	$(eval SNS_TOPIC=$(shell cd ../shared && terraform output -raw sns_topic))
	@echo "sns_topic = \"$(SNS_TOPIC)\"" >> warehouse.tfvars
	# Append only warehouse credentials
	@grep '^warehouse_db_' ../secrets.tfvars >> warehouse.tfvars
	@echo "Done: warehouse.tfvars created"

build:
	@echo "Packaging warehouse_loader Lambda code with dependencies..."
	rm -rf ../../lambda_build_warehouse
	mkdir -p ../../lambda_build_warehouse ../../builds
	pip install -r ../../requirements.txt --target=../../lambda_build_warehouse
	cp ../../warehouse_loader.py ../../lambda_build_warehouse/
	# If you have utils, include them (optional)
	cp -r ../../utils ../../lambda_build_warehouse/ || true
	cd ../../lambda_build_warehouse && zip -r ../builds/warehouse_loader-lambda.zip .
	@echo "Lambda package created at ../../builds/warehouse_loader-lambda.zip"
	aws s3 cp ../../builds/warehouse_loader-lambda.zip s3://etl-data-project-007/builds/warehouse_loader-lambda.zip

init:
	terraform init

plan:
	terraform plan -var-file="warehouse.tfvars"

apply:
	terraform apply -var-file="warehouse.tfvars" -auto-approve

destroy:
	terraform destroy -var-file="warehouse.tfvars" -auto-approve

deploy: build init plan apply
	@echo "Warehouse loader module built and deployed."

.PHONY: build init plan apply destroy deploy generate-tfvars
