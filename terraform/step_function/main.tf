resource "aws_iam_role" "step_function_role" {
  name = "etl_step_function_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "states.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "step_function_policy" {
  name = "ETLStepFunctionPolicy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction"
        ],
        Resource = [
          var.ingestion_lambda_arn,
          var.transformation_lambda_arn,
          var.warehouse_loader_lambda_arn
        ]
      }
    ]
  })
}

resource "aws_sfn_state_machine" "etl_pipeline" {
  name     = "etl-pipeline"
  role_arn = aws_iam_role.step_function_role.arn

  definition = <<EOF
{
  "Comment": "ETL Pipeline",
  "StartAt": "Ingestion",
  "States": {
    "Ingestion": {
      "Type": "Task",
      "Resource": "${var.ingestion_lambda_arn}",
      "ResultPath": "$.ingestion_result",
      "Next": "Transformation"
    },
    "Transformation": {
      "Type": "Task",
      "Resource": "${var.transformation_lambda_arn}",
      "InputPath": "$.ingestion_result",
      "ResultPath": "$.transformation_result",
      "Next": "WarehouseLoader"
    },
    "WarehouseLoader": {
      "Type": "Task",
      "Resource": "${var.warehouse_loader_lambda_arn}",
      "InputPath": "$.transformation_result",
      "End": true
    }
  }
}
EOF
}
