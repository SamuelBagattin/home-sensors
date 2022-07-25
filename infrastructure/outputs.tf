output "sensor1-certificate" {
  value     = module.iot_thing_topic_sensor1.thing_certificate_pem
  sensitive = true
}