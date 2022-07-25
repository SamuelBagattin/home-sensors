resource "aws_iam_role" "sensors_iot_rule_errors" {
  name               = "homesensors-iot-ruleerrors-role"
  assume_role_policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[{
      "Effect": "Allow",
      "Principal": {
        "Service": "iot.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
  }]
}
EOF
}

data "aws_iam_policy_document" "sensors_iot_rule_errors" {
  statement {
    effect = "Allow"
    actions = [
      "logs:*",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "sensors_iot_rule_errors" {
  policy = data.aws_iam_policy_document.sensors_iot_rule_errors.json
  name   = "homesensors-${var.sensor_name}-policy"
}

resource "aws_iam_role_policy_attachment" "sensors_iot_rule_errors" {
  policy_arn = aws_iam_policy.sensors_iot_rule_errors.arn
  role       = aws_iam_role.sensors_iot_rule_errors.name
}

resource "aws_iot_thing" "sensor" {
  name = "homesensors-${var.sensor_name}-thing"
}

resource "aws_iot_certificate" "sensor" {
  active = true
}

resource "aws_iot_thing_principal_attachment" "sensor" {
  principal = aws_iot_certificate.sensor.arn
  thing     = aws_iot_thing.sensor.name
}

resource "aws_iot_topic_rule" "sensor" {
  enabled     = true
  name        = "homesensors_${var.sensor_name}_topicrule"
  sql         = "SELECT *, topic() as topic FROM 'homesensors/${var.sensor_name}/topic'"
  sql_version = "2016-03-23"
  lambda {
    function_arn = var.destination_lambda_function_arn
  }
  error_action {
    cloudwatch_logs {
      log_group_name = var.errors_log_group_name
      role_arn       = aws_iam_role.sensors_iot_rule_errors.arn
    }
  }
}



resource "aws_iot_policy" "sensor" {
  name   = "homesensors-${var.sensor_name}-iotPolicy"
  policy = data.aws_iam_policy_document.sensor_iot_policy.json
}

data "aws_iam_policy_document" "sensor_iot_policy" {
  statement {
    effect = "Allow"
    actions = [
      "iot:Publish",
      "iot:Connect"
    ]
    resources = [
      aws_iot_thing.sensor.arn
    ]
  }
}

resource "aws_iot_policy_attachment" "sensor" {
  policy = aws_iot_policy.sensor.name
  target = aws_iot_certificate.sensor.arn
}


