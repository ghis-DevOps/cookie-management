variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cookie-management"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "owner" {
  description = "Application owner"
  type        = string
}

variable "cookie_api_url" {
  description = "Cookie Management platform API endpoint"
  type        = string
}

variable "cookie_api_secret_name" {
  description = "Secrets Manager secret containing the Cookie Management API credentials"
  type        = string
  default     = "cookie-management/api"
}

variable "scan_schedule" {
  description = "Website scan schedule in EventBridge cron/rate format"
  type        = string
  default     = "rate(7 days)"
}

variable "publish_schedule" {
  description = "Cookie script publishing schedule"
  type        = string
  default     = "rate(7 days)"
}

variable "applications" {
  description = "Applications managed by the Cookie Management platform"
  type = map(object({
    website_url = string
    category    = string
    brand       = string
    enabled     = optional(bool, true)
  }))
}