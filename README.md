# ToteSys ETL Pipeline (AWS + Terraform + Python)

## Project Purpose

This project is an **ETL (Extract–Transform–Load) data pipeline** for ToteSys, designed to automate the movement and transformation of data from a production PostgreSQL database to a cloud-based data warehouse.
The system is modular, production-ready, and supports parallel team development using AWS Lambda, S3, and Terraform.

## Tech Stack and Dependencies

* **Python** (3.11 recommended)
* **AWS** (Lambda, S3, CloudWatch, SNS, IAM, Step Functions)
* **Terraform** (1.4+)
* **pg8000** (PostgreSQL driver for Python)
* **pytest** (for testing)
* **flake8** / **black** (for linting and code style)
* **bandit** (for security scanning)
* **pip-audit** (optional, package vulnerability checks)

> Other dependencies are managed via `requirements.txt` and `requirements-dev.txt`.

## Architecture

```
ToteSys Database
        |
   Ingestion Lambda
        |
        v
       S3 (Raw Data)
        |
Transformation Lambda
        |
        v
     S3 (Processed Data)
        |
Warehouse Loader Lambda
        |
        v
 Data Warehouse (PostgreSQL)
```

* Each Lambda runs independently and communicates via S3 and event payloads.
* State and incremental loading supported via S3 state files.

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <your_repo_url>
cd totesys-etl-pipeline
```

### 2. Python Environment and Dependencies

```bash
make venv           # Create virtual environment (using venv)
make install        # Install production dependencies
make dev-install    # Install dev/testing tools (pytest, flake8, etc.)
```

### 3. Configure AWS Credentials

Set up your AWS CLI profile with credentials that have permission to manage S3, Lambda, IAM, etc.

```bash
aws configure
# Enter Access Key, Secret Key, region: eu-west-2, output: json
```

### 4. Prepare Secrets and Variables

Copy example secrets/vars and fill in real values (do not commit real secrets):

```bash
cp terraform/secrets.tfvars.example terraform/secrets.tfvars
# Edit terraform/secrets.tfvars with your actual DB/Warehouse credentials and alert email
```

### 5. Terraform Backend Bucket (ONE TIME)

Create the S3 bucket for Terraform state storage (do this once for the whole team):

```bash
make -f scripts/Makefile.oneoff create-tfstate-bucket
```

> The default bucket name is `project-team-07-tfstate`.

### 6. Initialize Terraform Modules

Each module (`shared`, `ingestion`, `transformation`, `warehouse_loader`, `step_function`) has its own folder, backend, and Makefile.

To deploy a module (for example, ingestion):

```bash
cd terraform/ingestion
make init
make generate-tfvars
make build
make plan
make apply
```

Or, for most modules, just:

```bash
make deploy
```

**Never use the same backend `key` in more than one module!**
Each module should have a unique state file.

### 7. Deploy the Shared Infrastructure (S3, IAM, SNS, etc.)

```bash
cd terraform/shared
make init
make plan
make apply
```

### 8. Deploy and Test All Pipeline Modules

Repeat for each of the following (in their respective directories):

* ingestion
* transformation
* warehouse\_loader
* step\_function

**Always use the Makefile in the module directory for convenience and to avoid mistakes.**

## Testing and Linting

To run tests and check code style, from the project root:

```bash
make test       # Runs all pytest tests
make lint       # Run flake8 linter
make format     # Auto-format code with black
make check-format  # Check code formatting without changing files
make bandit     # Run security checks
```

## Typical Development and Deployment Workflow

1. Pull the latest changes from git.
2. Create or update your virtual environment (`make venv`).
3. Install or update dependencies (`make install` or `make dev-install`).
4. Check/update secrets in `terraform/secrets.tfvars`.
5. Use the Makefile in your module folder to build, plan, and apply Terraform.
6. Monitor your Lambda and S3 output via AWS Console.

## Project Structure

```
/terraform/
  shared/            # Shared resources: S3, IAM, SNS
  ingestion/         # Ingestion Lambda, triggers, backend
  transformation/    # Transformation Lambda, backend
  warehouse_loader/  # Loader Lambda, backend
  step_function/     # Orchestration (Step Functions)
builds/              # Lambda deployment packages (created by Makefiles)
lambda_build/        # Temporary build directories
utils/               # (Optional) Python shared utilities
requirements.txt     # Production Python dependencies
requirements-dev.txt # Dev/testing/linting dependencies
secrets.tfvars.example  # Example secrets file
```

## Team/Collaboration Conventions

* Only one person manages `shared/` (S3, IAM, SNS).
* Announce in chat before running any "one-off" (see `scripts/Makefile.oneoff`).
* Never destroy or apply another person's module without their consent.
* Each person works in their own module, using a unique backend key.
* Commit only your code and configs, **never commit secrets or `.tfvars` files**.

## Troubleshooting

* If you get a Terraform state lock error:
  Someone else is running `terraform apply` in that folder. Wait and try again.
* If a Lambda or infra resource fails to deploy, check the AWS Console logs and CloudWatch for errors.
* For questions about backend configuration, environment variables, or credentials, ask in team chat.

## Contribution and Extending

* To add new tables or data sources, update the ingestion/extraction scripts and add corresponding transforms.
* To extend the pipeline (e.g. add reporting or BI), add new Lambda modules or extend the warehouse loader logic.
* All new code must include tests (`pytest`), pass lint (`flake8`), and be formatted (`black`).

## License and Contact

For help or issues, reach out via your team Slack/Discord or GitHub Issues.
Project maintained by ToteSys Data Engineering Team.
