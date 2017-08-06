variable "runtime" {
  default = "python2.7"
}

variable "name" {}

variable "handler" {
  default = "handler"
}

variable "role" {}

# Here is a first lambda function that will run the code `rotor.handler`
resource "aws_lambda_function" "lambda" {
  filename         = "${var.name}.zip"
  function_name    = "${var.name}_${var.handler}"
  handler          = "${var.name}.${var.handler}"
  runtime          = "${var.runtime}"
  role             = "${var.role}"
  source_code_hash = "${base64sha256(file("${var.name}.zip"))}"
}

output "name" {
  value = "${aws_lambda_function.lambda.function_name}"
}
