variable "alert_threshold_eur" {
  description = "Alert when monthly cost exceeds this amount (eur)"
  type        = number
  default     = 100
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


variable "aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "aws_secret_access_key" {
  type      = string
  sensitive = true
}