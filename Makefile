# Path to the virtual environment directory
VENV_PATH = venv
PYTHON = $(VENV_PATH)/bin/python
PIP = $(VENV_PATH)/bin/pip

# ------------------------------------------------------------------------------
# Create a virtual environment in the specified folder (default: ./venv)
# Usage: make venv
# ------------------------------------------------------------------------------
venv:
	python -m venv $(VENV_PATH)

# ------------------------------------------------------------------------------
# Install all required Python packages from requirements.txt
# Usage: make install
# Requires: make venv should be run beforehand
# ------------------------------------------------------------------------------
install:
	$(PIP) install -r requirements.txt

# ------------------------------------------------------------------------------
# Run tests using pytest
# Usage: make test
# ------------------------------------------------------------------------------
test:
	@echo "Running pytest..."
	pytest -vvvrP


# ------------------------------------------------------------------------------
# Initialize the Terraform working directory
# Usage: make tf-init
# ------------------------------------------------------------------------------
tf-init:
	cd terraform && terraform init

# ------------------------------------------------------------------------------
# Apply the Terraform configuration to provision resources
# Usage: make tf-apply
# ------------------------------------------------------------------------------
tf-apply:
	cd terraform && terraform apply -auto-approve

# ------------------------------------------------------------------------------
# Destroy the Terraform-managed infrastructure
# Usage: make tf-destroy
# ------------------------------------------------------------------------------
tf-destroy:
	cd terraform && terraform destroy -auto-approve

all: venv install tf-init tf-apply
