output "thing_certificate_pem" {
  value       = aws_iot_certificate.sensor.certificate_pem
  description = "The certificate PEM"
}

output "topic_rule_arn" {
  value       = aws_iot_topic_rule.sensor.arn
  description = "The ARN of the topic rule"
}