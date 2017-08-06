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

module "lambda" {
  source = "./lambda"
  name   = "rotor"
  role   = "${aws_iam_role.iam_role_for_lambda.arn}"
}

resource "aws_api_gateway_rest_api" "rotor_api" {
  name = "Rotor API"
}

resource "aws_api_gateway_resource" "rotor_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.rotor_api.root_resource_id}"
  path_part   = "rotor"
}

resource "aws_api_gateway_resource" "rotor_api_proxy_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  parent_id   = "${aws_api_gateway_resource.rotor_api_resource.id}"
  path_part   = "{rotorId}"
}

resource "aws_api_gateway_resource" "rotor_api_proxy_name_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  parent_id   = "${aws_api_gateway_resource.rotor_api_proxy_resource.id}"
  path_part   = "name"
}


module "rotor_get" {
  source      = "./apigateway"
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  resource_id = "${aws_api_gateway_resource.rotor_api_resource.id}"
  account_id  = "${var.account_id}"
  region      = "${var.region}"
  http_method = "GET"
  lambda      = "${module.lambda.name}"
  path        = "${aws_api_gateway_resource.rotor_api_resource.path}"
  request_template = {
    "application/json" = "{\"func\": \"get_handler\"}"
  }

}

module "rotor_post" {
  source      = "./apigateway"
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  resource_id = "${aws_api_gateway_resource.rotor_api_resource.id}"
  account_id  = "${var.account_id}"
  region      = "${var.region}"
  http_method = "POST"
  lambda      = "${module.lambda.name}"
  path        = "${aws_api_gateway_resource.rotor_api_resource.path}"
  request_template = {
     "application/json" = "{\"func\": \"post_handler\"}"
  }

}

module "rotor_get_vpath" {
  source      = "./apigateway"
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  resource_id = "${aws_api_gateway_resource.rotor_api_proxy_resource.id}"
  account_id  = "${var.account_id}"
  region      = "${var.region}"
  http_method = "GET"
  lambda      = "${module.lambda.name}"
  path        = "${aws_api_gateway_resource.rotor_api_proxy_resource.path}"
  request_parameters = {
    "method.request.path.rotorId" = true
  }

  request_template = {
    "application/json" = "{\"func\": \"vpath_handler\", \"parameters\": {\"rotor_id\": \"$input.params('rotorId')\" }}"
  }
}

module "rotor_get_name" {
  source      = "./apigateway"
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  resource_id = "${aws_api_gateway_resource.rotor_api_proxy_name_resource.id}"
  account_id  = "${var.account_id}"
  region      = "${var.region}"
  http_method = "GET"
  lambda      = "${module.lambda.name}"
  path        = "${aws_api_gateway_resource.rotor_api_proxy_name_resource.path}"
  request_parameters = {
    "method.request.path.rotorId" = true
  }

  request_template = {
    "application/json" = "{\"func\": \"get_rotor_name\", \"parameters\": {\"rotor_id\": \"$input.params('rotorId')\" }}"
  }
}

resource "aws_lambda_permission" "allow_api_gateway" {
  function_name = "${module.lambda.name}"
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.rotor_api.id}/*"
}

resource "aws_api_gateway_deployment" "rotor_api_deployment" {
  rest_api_id = "${aws_api_gateway_rest_api.rotor_api.id}"
  stage_name  = "v1"
  description = "Deploy methods: GET"
}
