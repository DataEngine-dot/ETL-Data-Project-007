# 🛠️ Data Engineering Project: ToteSys ETL Pipeline

## Project Description

This project implements an **Extract–Transform–Load (ETL)** pipeline using AWS services and Python.

The goal is to extract data from a simulated operational database (ToteSys), transform it into an analytical format using a star schema, and load it into a cloud data warehouse for business intelligence use.

The project demonstrates practical use of:
- AWS (S3, Lambda, EventBridge, CloudWatch, SNS)
- Terraform (Infrastructure-as-Code)
- Python (`pg8000`, `pandas`, `pyarrow`, `sqlalchemy`)
- CI/CD practices
- Data warehousing principles
- Automated testing and security auditing

---

## Architecture Overview

```txt
+-------------+       +-------------+       +-------------+       +-------------+
|  ToteSys DB | --->  |  Ingestion  | --->  | Transformation | ---> | Data Warehouse |
+-------------+       +-------------+       +-------------+       +-------------+
```
---

## Features

- Scheduled ingestion from PostgreSQL to S3 (`ingestion/`)
- Transformation of raw data into star schema format (`processed/`)
- Loading dimension and fact tables into a data warehouse
- Infrastructure managed via Terraform
- Monitoring, logging, and alerting (CloudWatch + SNS)
- Security checks with `bandit`, `pip-audit`
- Unit tests using `pytest`

---

## Tech Stack

| Layer        | Tools & Services                      |
|--------------|----------------------------------------|
| Programming  | Python 3, pandas, pyarrow, sqlalchemy |
| Cloud        | AWS (S3, Lambda, CloudWatch, EventBridge, SNS) |
| Infrastructure | Terraform, GitHub Actions (CI/CD)  |
| Database     | PostgreSQL / Amazon Redshift          |
| Testing      | Pytest, pip-audit, bandit             |
| Visualisation| AWS QuickSight / Jupyter Notebook     |

---

## Development Phases

1. **Data Ingestion** – Extract from ToteSys → S3 (`ingestion/`)
2. **Data Transformation** – JSON → Parquet → S3 (`processed/`)
3. **Warehouse Loading** – Load into fact/dim tables with history
4. **Visualisation** – QuickSight dashboards + analysis
5. **CI/CD & Security** – Full pipeline, testing, and automation

---

## Project Status

> _[Update this section as progress continues]_  
- [x] Ingestion Lambda live  
- [ ] Transformation tested  
- [ ] Warehouse integration in progress  
- [ ] Visualisation configured  
- [ ] Final testing & deployment

---
## How to Run

```bash
# Deploy infrastructure
make terraform-init
make terraform-apply

---

