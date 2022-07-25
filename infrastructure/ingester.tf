data "archive_file" "ingester" {
  type = "zip"

  source_dir  = local.ingester_out_dir
  output_path = "${local.ingester_zip_out_dir}/ingester.zip"
}

data "aws_s3_bucket" "lambda_artifacts" {
  bucket = "samuel-lambda-artifacts"
}

resource "aws_s3_object" "ingester_artifact" {
  bucket = data.aws_s3_bucket.lambda_artifacts.id

  key    = "ingester.zip"
  source = data.archive_file.ingester.output_path

  etag = filemd5(data.archive_file.ingester.output_path)
}

resource "aws_lambda_function" "ingester" {
  function_name    = "homesensor-ingester-lambdaFunction"
  handler          = "main.handler"
  role             = aws_iam_role.ingester_role.arn
  runtime          = "python3.9"
  architectures    = ["arm64"]
  s3_bucket        = aws_s3_object.ingester_artifact.bucket
  s3_key           = aws_s3_object.ingester_artifact.key
  source_code_hash = data.archive_file.ingester.output_base64sha256
  timeout          = 15
  memory_size      = 128
  environment {
    variables = {
      "INFLUXDB_URL"                          = local.influxdb_url
      "INFLUXDB_API_TOKEN_SSM_PARAMETER_NAME" = local.ingester_influxdb_apitoken_ssm_parameter_name
    }
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_function_event_invoke_config" "ingester" {
  function_name = aws_lambda_function.ingester.function_name
  destination_config {
    on_failure {
      destination = aws_sqs_queue.ingester_dlq.arn
    }
  }
}

resource "aws_lambda_permission" "ingester_from_iot_sensors" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingester.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = module.iot_thing_topic_sensor1.topic_rule_arn
}

resource "aws_iam_role" "ingester_role" {
  assume_role_policy = data.aws_iam_policy_document.ingester_assumerole.json
  name               = "homesensor-ingester-role"
}

data "aws_iam_policy_document" "ingester_assumerole" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    effect = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "basic_lambda" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.ingester_role.name
}
resource "aws_iam_role_policy_attachment" "xray_lambda" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.ingester_role.name
}

resource "aws_iam_policy_attachment" "ingester" {
  name       = "homesensors-ingester-mainPolicy-attachment"
  policy_arn = aws_iam_policy.ingester.arn
  roles      = [aws_iam_role.ingester_role.name]
}

resource "aws_iam_policy" "ingester" {
  name   = "homesensors-ingester-mainPolicy"
  policy = data.aws_iam_policy_document.ingester_main.json
}

data "aws_ssm_parameter" "ingester_influxdb_apitoken" {
  name            = local.ingester_influxdb_apitoken_ssm_parameter_name
  with_decryption = false
}

data "aws_iam_policy_document" "ingester_main" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.ingester_dlq.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [data.aws_ssm_parameter.ingester_influxdb_apitoken.arn]
  }
}

resource "aws_sqs_queue" "ingester_dlq" {
  name                    = "homesensor-ingester-dlq"
  sqs_managed_sse_enabled = true
}