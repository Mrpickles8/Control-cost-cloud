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


variable "TF_API_TOKEN" {
  description = "token terraform"
  type        = string
  sensitive   = true
}