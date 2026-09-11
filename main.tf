# CloudWatch Dashboard Configuration for Payments API Monitoring
# This file defines variables, dashboard metrics, and outputs for the monitoring infrastructure.

# Service name used for dashboard naming and resource identification
variable "service_name" {
  type    = string
  default = "payments-api"
}

variable "environment" {
  type    = string
  default = "prod"
}

locals {
  dashboard_region = "us-east-1"

  alb_peak_lcu_metrics = [
    ["AWS/ApplicationELB", "PeakLCUs", "LoadBalancer", "app/Spacelift-ALB/bfc0df6a93c97a22"],
  ]

  billing_metrics = [
    ["AWS/Billing", "EstimatedCharges", "Currency", "USD"],
  ]

  ec2_cpu_metrics = [
    ["AWS/EC2", "CPUUtilization"],
  ]

  eks_4xx_metrics = [
    ["AWS/EKS", "apiserver_request_total_4XX", "ClusterName", "eks-cluster"],
  ]

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ALB Peak LCUs"
          region  = local.dashboard_region
          metrics = local.alb_peak_lcu_metrics
          stat    = "Maximum"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Estimated Charges (USD)"
          region  = local.dashboard_region
          metrics = local.billing_metrics
          stat    = "Maximum"
          period  = 21600
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "EC2 CPU Utilization"
          region  = local.dashboard_region
          metrics = local.ec2_cpu_metrics
          stat    = "Average"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "EKS API Server 4XX Requests"
          region  = local.dashboard_region
          metrics = local.eks_4xx_metrics
          stat    = "Sum"
          period  = 300
        }
      },
    ]
  })
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.service_name}-${var.environment}"
  dashboard_body = local.dashboard_body
}

# Output the CloudWatch dashboard URL for easy access
output "dashboard_url" {
  value = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.this.dashboard_name}"
}

resource "random_string" "demo_bucket_suffix" {
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "aws_s3_bucket" "demo_bucket" {
  bucket = "spacelift-demo-bucket-${random_string.demo_bucket_suffix.result}"
  tags = {
    environment = var.environment
    managed_by  = "spacelift-demo"
    budget      = "10000"
    design      = "Scrum"
    workflow    = "Waterfall"
  }
}
