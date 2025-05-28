resource "aws_cloudwatch_log_group" "extraction_cloudwatch_log" {
    name= "extraction_cloudwatch"
    
}


resource "aws_cloudwatch_metric_alarm" "extract_cloudwatch_alarm" {
    alarm_name = "extract_cloudwatch_alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 2
    period = 1800
    metric_name = "CPUUtilization"
    statistic = "Average"
    namespace = "AWS/Lambda"
}


