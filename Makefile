# ---------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------

VENV_PATH = venv
PYTHON = $(VENV_PATH)/bin/python
PIP = $(VENV_PATH)/bin/pip

LAMBDA_BUILD_DIR = builds
LAMBDA_ZIP_NAME = ingestion-lambda.zip
LAMBDA_ZIP_PATH = $(LAMBDA_BUILD_DIR)/$(LAMBDA_ZIP_NAME)
LAYER_ZIP_NAME = lambda-layer.zip
LAYER_ZIP_PATH = $(LAMBDA_BUILD_DIR)/$(LAYER_ZIP_NAME)

PACKAGE_DIR = lambda_build
LAYER_DIR = lambda_layer/python

# ---------------------------------------------------------------------
# ENVIRONMENT SETUP
# ---------------------------------------------------------------------

venv:
	python -m venv $(VENV_PATH)

install:
	$(PIP) install -r requirements.txt

# ---------------------------------------------------------------------
# CLEANUP
# ---------------------------------------------------------------------

clean:
# Remove build and temporary directories
	rm -rf $(PACKAGE_DIR) $(LAYER_DIR) $(LAMBDA_BUILD_DIR)

clean-layer:
	rm -rf lambda_layer

# ---------------------------------------------------------------------
# BUILD LAMBDA FUNCTION CODE ONLY (no dependencies)
# ---------------------------------------------------------------------

build-lambda:
	@echo "Packaging Lambda code only (without dependencies)..."
	rm -rf $(PACKAGE_DIR)
	mkdir -p $(PACKAGE_DIR)
	mkdir -p $(LAMBDA_BUILD_DIR)
	cp ingestion.py $(PACKAGE_DIR)/
	cp -r utils $(PACKAGE_DIR)/
	cd $(PACKAGE_DIR) && zip -r ../$(LAMBDA_ZIP_PATH) .

# ---------------------------------------------------------------------
# BUILD LAMBDA LAYER (dependencies only)
# ---------------------------------------------------------------------

build-layer:
	@echo "Packaging Lambda Layer with all dependencies ..."
	mkdir -p $(LAYER_DIR)
	pip install -r requirements.txt --target=$(LAYER_DIR)
	cd lambda_layer && zip -r ../$(LAYER_ZIP_PATH) .
	rm -rf lambda_layer

# ---------------------------------------------------------------------
# TERRAFORM
# ---------------------------------------------------------------------

tf-init:
	cd terraform && terraform init

tf-apply: build-lambda build-layer
	cd terraform && terraform apply -auto-approve

tf-destroy:
	cd terraform && terraform destroy -auto-approve

# ---------------------------------------------------------------------
# FULL WORKFLOW
# ---------------------------------------------------------------------

all: clean venv install tf-init tf-apply
