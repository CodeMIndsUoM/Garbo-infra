resource "aws_cloudwatch_log_group" "backend" {
  name              = "/garbo/${var.project_name}/backend"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/garbo/${var.project_name}/frontend"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Garbo EC2 CPU above 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.ec2_instance_id
  }

  tags = var.tags
}
