mock_provider "aws" {
  override_during = plan
  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:us-east-1:123456789012:certificate/mock"
      domain_validation_options = [{
        domain_name           = "api.sandbox.example.com"
        resource_record_name  = "_validation.api.sandbox.example.com"
        resource_record_value = "_validation.acm-validations.aws."
        resource_record_type  = "CNAME"
      }]
    }
  }
  mock_data "aws_route53_zone" {
    defaults = {
      zone_id = "Z_EXPLICIT_CHILD"
      name    = "sandbox.example.com."
    }
  }
}

variables {
  domain         = "api.sandbox.example.com"
  hosted_zone_id = "Z_EXPLICIT_CHILD"
  function_arn   = "arn:aws:lambda:us-east-1:123456789012:function:example-api"
}

run "unqualified_function" {
  command = plan

  assert {
    condition     = aws_lambda_permission.api_gateway.function_name == var.function_arn && aws_lambda_permission.api_gateway.qualifier == null
    error_message = "An unqualified function ARN must keep its original invocation permission."
  }

  assert {
    condition     = aws_route53_record.this.zone_id == "Z_EXPLICIT_CHILD"
    error_message = "The explicit child zone must own the API record."
  }
}

run "qualified_function" {
  command = plan

  variables {
    function_arn = "arn:aws:lambda:us-east-1:123456789012:function:example-api:live"
  }

  assert {
    condition     = aws_lambda_permission.api_gateway.function_name == "arn:aws:lambda:us-east-1:123456789012:function:example-api" && aws_lambda_permission.api_gateway.qualifier == "live"
    error_message = "Qualified permissions must keep the base function ARN and qualifier separate."
  }

  assert {
    condition     = endswith(aws_api_gateway_integration.lambda_root.uri, "/functions/${var.function_arn}/invocations") && endswith(aws_api_gateway_integration.lambda_proxy.uri, "/functions/${var.function_arn}/invocations")
    error_message = "Both API integrations must invoke the qualified target."
  }
}
