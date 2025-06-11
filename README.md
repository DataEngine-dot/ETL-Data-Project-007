# 🛠️ ToteSys ETL Pipeline (AWS + Terraform + Python)

## 📌 Project Description

This project is an **ETL (Extract–Transform–Load)** pipeline using AWS and Python.  
We read data from ToteSys database, save it to S3, transform it, and finally load it into a data warehouse.

---

## 🧱 Architecture

```
ToteSys DB --> Ingestion (Lambda) --> Transformation (Lambda) --> Data Warehouse
                 |                        |
              S3 + SNS                 S3 (Parquet)
```

---

## ✨ Key Features

- Independent infrastructure for each module (no blocking between team members)
- One S3 bucket for all Terraform state files, but each module uses its own state file (backend)
- **Quick parallel deployment:** Everyone can work on their part at the same time!
- AWS Lambda for scheduled ingestion and processing
- CloudWatch and SNS alerting
- Automated tests (pytest), code linting, and security checks
- Modular structure for fast development

---

## 🚀 Quick Start / Deployment

### 1. Clone and prepare environment

```bash
git clone <repo_url>
cd totesys-etl-pipeline
cp .env.example .env
```

### 2. Set up Python environment

```bash
make venv
make install         # For production dependencies
make dev-install     # For development and testing tools
```

### 3. Create S3 bucket for Terraform backend (ONE TIME, whole team)
One person should run this and tell the team after:

```bash
make -f scripts/Makefile.oneoff create-tfstate-bucket
```

> This creates the S3 bucket `my-totesys-tfstate` to store Terraform state files for all modules.

---

### 4. Backend configuration for each Terraform module

Each module (`shared`, `ingestion`, `transformation`, `warehouse_loader`) has its own `backend.tf` file.  
**Do not use the same "key" in two places!**  
**This lets each person deploy/apply/destroy their module without blocking others.**

Example for ingestion:
```hcl
terraform {
  backend "s3" {
    bucket = "my-totesys-tfstate"
    key    = "ingestion/terraform.tfstate"
    region = "eu-west-2"
  }
}
```
(Already included for you in the repo.)

---

### 5. Initialize backend and deploy your own module

Each team member goes into their own folder and runs:

```bash
cd terraform/<your_module>
terraform init
terraform plan -var-file="secrets.tfvars"
terraform apply -var-file="secrets.tfvars" -auto-approve
```
- You can also use the Makefile in each folder:  
  `make init`  
  `make plan`  
  `make apply`

---

### 6. Run and test your code

```bash
make test       # Run all tests (pytest)
make lint       # Lint code (flake8)
make format     # Format code (black)
```

---

## 🏗️ Project Structure

```
terraform/
├── shared/            # S3 bucket, SNS, IAM (one person manages)
├── ingestion/         # Ingestion Lambda and triggers
├── transformation/    # Transformation Lambda
├── warehouse_loader/  # Load data into warehouse
```

Each module is independent!  
**Do not destroy or apply other people's modules.**

---

## 📁 Terraform Backend: How it works

- One S3 bucket: `my-totesys-tfstate`
- Each module: different "key" (state file)
    - Example: `ingestion/terraform.tfstate`
- Everyone works in their own module, at the same time, without blocking.

**How to use:**
1. Go to your module folder (for example: `cd terraform/ingestion`)
2. Run `terraform init` (first time)
3. Now you can plan, apply, or destroy only your module

---

## 🧪 Testing & Security

- Tests: `pytest` in the `tests/` folder
- Lint: `flake8`
- Format: `black`
- Security: `bandit`, `pip-audit`

---

## 🔐 Email Alerts

- Configure your alert email in `terraform/secrets.tfvars`
- **Do not commit secrets.tfvars to git!**
- After first deploy, check your email and confirm the AWS subscription for alerts.

---

## 📣 Notes for Team

- Only one person should manage `shared/` module (S3 bucket, IAM, SNS).
- Announce in chat before running any "one-off" command (see `scripts/Makefile.oneoff`).
- **Do not destroy another person's module.** Each person manages their own part.

---

## 🆘 Troubleshooting

- If you see a "state lock" error, check if someone else is running `terraform apply` in the same folder.
- If unsure about backend or deployment, ask in team chat.

---

## 📬 Contact

For help or questions, reach out in your team chat or GitHub Issues.

---