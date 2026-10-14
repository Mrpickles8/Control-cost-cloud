variable "alert_threshold_usd" {
  description = "Alert when monthly cost exceeds this amount (eur)"
  type        = number
  default     = 1
}

variable "alert_email" {
  description = "Email to receive the alerts"
  type        = string
  sensitive   = true
}

variable "aws_region_E" {
  description = "Email to receive the alerts"
  type        = string
  default     = "eu-west-1"
}

variable "aws_region_U" {
  description = "Email to receive the alerts"
  type        = string
  default     = "us-east-1"
}

