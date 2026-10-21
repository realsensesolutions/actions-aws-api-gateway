variable "domain" {
  description = "Custom domain for the API Gateway (e.g., api.example.com)"
  type        = string

  validation {
    condition     = length(var.domain) > 0 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\-\\.]*[a-zA-Z0-9]$", var.domain))
    error_message = "Domain must be a valid domain name format"
  }
}

variable "function_arn" {
  description = "ARN of the Lambda function to proxy all requests to"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:lambda:", var.function_arn))
    error_message = "Function ARN must be a valid Lambda function ARN"
  }
}

variable "hosted_zone_domain" {
  description = "Route53 hosted zone domain name (found by the hosted zone search)"
  type        = string

  validation {
    condition     = length(var.hosted_zone_domain) > 0
    error_message = "Hosted zone domain cannot be empty"
  }
}