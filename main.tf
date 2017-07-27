provider "aws" {
  region = "${var.region}"
}
variable "account_id" {
  default = "452395698705"
}

variable "region" {
  default = "us-west-1"
}

# First, we need a role to play with Lambda
resource "aws_iam_role" "iam_role_for_lambda" {
  name = "iam_role_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Here is a first lambda function that will run the code `rotor.handler`
resource "aws_lambda_function" "lambda" {
  filename      = "rotor.zip"
  function_name = "rotor_handler"
  handler       = "rotor.handler"
  runtime       = "python2.7"
  role    = "${aws_iam_role.iam_role_for_lambda.arn}"
  source_code_hash = "${base64sha256(file("rotor.zip"))}"
}

resource "aws_api_gateway_rest_api" "rotor_api" {
  name = "Rotor API"
}

resource "aws_api_gateway_resource" "rotor_api_res" {
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  parent_id = "${aws_api_gateway_rest_api.rotor_api.root_resource_id}"
  path_part = "rotor"
}

resource "aws_api_gateway_method" "request_method" {
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  resource_id = "${aws_api_gateway_resource.rotor_api_res.id}"
  http_method = "GET"
  authorization = "None"
}

resource "aws_api_gateway_integration" "request_method_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  resource_id = "${aws_api_gateway_resource.rotor_api_res.id}"
  http_method = "${aws_api_gateway_method.request_method.http_method}"
  type        = "AWS"
  uri         = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:rotor_handler/invocations"

  # AWS lambdas can only be invoked with the POST method
  integration_http_method = "POST"
}

resource "aws_api_gateway_method_response" "response_method" {
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  resource_id = "${aws_api_gateway_resource.rotor_api_res.id}"
  http_method = "${aws_api_gateway_integration.request_method_integration.http_method}"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "response_method_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  resource_id = "${aws_api_gateway_resource.rotor_api_res.id}"
  http_method = "${aws_api_gateway_method_response.response_method.http_method}"
  status_code = "${aws_api_gateway_method_response.response_method.status_code}"
  response_templates = {
    "application/json" = ""
  }
}

resource "aws_lambda_permission" "allow_api_gateway" {
  function_name = "rotor_handler"
  statement_id = "AllowExecutionFromApiGateway"
  action = "lambda:InvokeFunction"
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.rotor_api.id}/*/${aws_api_gateway_method.request_method.http_method}${aws_api_gateway_resource.rotor_api_res.path}"
}

resource "aws_api_gateway_deployment" "rotor_api_deployment" {
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  stage_name = "v1"
  description = "Deploy methods: GET"
}
