1. Extraction (Ingestion)
Goal: Take data out of the production database (PostgreSQL).

How it works:

The script connects to the database.

For each table, it checks last_updated.json to know what was already copied.

It selects only new or changed rows (using last_updated > previous_timestamp).

It writes this data as CSV files to S3 and updates last_updated.json with the latest timestamps for each table.

2. Transformation
Goal: Clean, standardize, or enrich the extracted data.

How it works:

Reads raw CSV files from S3.

Applies rules to clean data (e.g., formats, removes bad rows, fixes values, adds computed columns).

Saves transformed data back to S3, usually as new files (could be Parquet or clean CSV).

3. Loading to Warehouse
Goal: Move clean, final data into the data warehouse (another PostgreSQL, Redshift, or similar).

How it works:

Reads the transformed files from S3.

Inserts (or upserts) the data into the target warehouse tables.

Ensures data integrity and that only new/changed records are loaded.

4. Orchestration & Automation
Goal: Make all steps run in the right order, automatically, and on schedule.

How it works:

AWS Step Functions or similar service runs each Lambda in sequence:

First Ingest (extract),

Then Transform,

Then Load.

Errors are logged and can trigger alerts (e.g., via SNS/email).

5. Monitoring & Notifications
Goal: Track pipeline health and send alerts.

How it works:

Logs from each stage are sent to CloudWatch.

On errors or completion, send notifications (using AWS SNS).

Typical Workflow Example
Scheduled event (e.g., every hour/day) triggers the Step Function.

Ingestion Lambda runs:

Checks what data is new.

Extracts new rows, saves CSVs to S3.

Updates the state file (last_updated.json).

Transformation Lambda runs:

Loads raw CSVs.

Cleans or transforms the data.

Saves cleaned files back to S3.

Warehouse Loader Lambda runs:

Loads transformed data into the data warehouse.

Updates warehouse tables.

Notifications are sent about success/failure.

Logs are available for debugging and auditing.

Why This Architecture?
Reliability: Each stage is isolated; errors in one stage don’t break the others.

Scalability: AWS handles most infrastructure, so it can grow with your data.

Traceability: Every run is logged, so you can see what happened and when.

Incrementality: Only new/changed data is processed, saving time and cost.


===========================


Check that your backend config uses the correct bucket name

Make sure all backend.tf files in your Terraform modules (shared, ingestion, etc.) use project-team-07-tfstate as the bucket name.

Set up your AWS credentials

Make sure your AWS CLI is configured to use the correct user with programmatic access.

Run:


aws configure
Enter your Access Key ID, Secret Access Key, region (eu-west-2), and default output (json).



create-tfstate-bucket:
	aws s3api create-bucket --bucket project-team-07-tfstate --region eu-west-2 --create-bucket-configuration LocationConstraint=eu-west-2
    @echo "Terraform S3 backend bucket created: project-team-07-tfstate"






Copy and fill in your secrets/variables

Copy the example secrets file and fill in your real credentials (do not commit this file):


cp terraform/secrets.tfvars.example terraform/secrets.tfvars
# Edit terraform/secrets.tfvars with your actual DB and alert details
Initialize the Terraform backend for each module


install dependencies:
pip install -r requirements.txt -t ./lambda_build/





Go to your main terraform/ folder:
cd terraform
terraform init
Do the same for each submodule (optional, if you want to deploy modules separately):


cd shared && terraform init
cd ../ingestion && terraform init
# etc.
Deploy the shared infrastructure

Go to the shared module:
cd terraform/shared
terraform apply -var-file="shared.tfvars" -auto-approve

This will create the core resources: S3 bucket for ingestion, IAM roles, SNS topic, etc.


======================
Deploy your other modules (ingestion, transformation, warehouse_loader)

For each module:

cd terraform/ingestion
make generate-tfvars


make deploy
# or, if not using the Makefile:
terraform plan -var-file="ingestion.tfvars"
terraform apply -var-file="ingestion.tfvars" -auto-approve
Check AWS Console for resources

Go to AWS Console and check that S3, Lambda, SNS, IAM, etc. resources are created.

