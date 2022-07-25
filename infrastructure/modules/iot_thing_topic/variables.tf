variable "destination_lambda_function_arn" {
  description = "Destination Lambda Function ARN"
  type        = string
}

variable "sensor_name" {
  description = "Sensor Name"
  type        = string
}

variable "errors_log_group_name" {
  description = "Errors Log Group name"
  type        = string
}