resource "aws_cloudwatch_log_group" "sensors_iot_rule_errors" {
  name              = "homesensors-sensors-iot-rule-errors"
  retention_in_days = 30
}

module "iot_thing_topic_sensor1" {
  source                          = "./modules/iot_thing_topic"
  destination_lambda_function_arn = aws_lambda_function.ingester.arn
  errors_log_group_name           = aws_cloudwatch_log_group.sensors_iot_rule_errors.name
  sensor_name                     = "sensor1"
}