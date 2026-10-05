variable "alert_threshold_eur" {
  description = "Alert when monthly cost exceeds this amount (eur)"
  type        = number
  default     = 100
}

variable "alert_email" {
  description = "Email to receive the alerts"
  type        = string
  default     = "davidartaud1@gmail.com"
}
