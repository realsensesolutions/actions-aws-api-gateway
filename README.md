# AWS API Gateway Action

This GitHub Action creates and manages AWS API Gateway with custom domain and Lambda proxy integration using Terraform.

## Features

- **API Gateway REST API** with Lambda proxy integration
- **Custom Domain** with SSL certificate (ACM)
- **Route53 DNS** configuration with automatic hosted zone detection
- **Lambda Proxy Integration** - routes all requests (`/{proxy+}` and `/`) to your Lambda function
- **Regional Configuration** - optimized for regional deployments
- **Infrastructure as Code** - managed via Terraform

## Usage

```yaml
permissions:
  id-token: write
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Check out repo
        uses: actions/checkout@v4
      
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: us-east-1
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: ${{ github.repository_owner }}-${{ github.actor }}

      - uses: alonch/actions-aws-backend-setup@main
        with:
          instance: webapp-demo

      # Deploy your Lambda function first
      - uses: alonch/actions-aws-function-node@main
        id: backend
        with: 
          name: my-api-function
          artifacts: backend
          entrypoint-file: src/app.js
          entrypoint-function: handler
          allow-public-access: true

      # Create API Gateway with custom domain
      - uses: ./
        with: 
          domain: api.example.com
          function: ${{ steps.backend.outputs.arn }}
```

## Inputs

| Name       | Description                                      | Required | Default |
|------------|--------------------------------------------------|----------|---------|
| `domain`   | Custom domain for the API Gateway (e.g., api.example.com) | Yes      | -       |
| `function` | Lambda function ARN to proxy all requests to    | Yes      | -       |
| `action`   | Desired outcome: `apply`, `plan`, or `destroy`   | No       | `apply` |

## Outputs

| Name                  | Description                                    |
|-----------------------|------------------------------------------------|
| `api_gateway_id`      | ID of the created API Gateway                  |
| `api_gateway_arn`     | ARN of the created API Gateway                 |
| `api_gateway_url`     | Direct URL of the API Gateway                  |
| `custom_domain_name`  | Custom domain name configured                  |

## How It Works

1. **Hosted Zone Detection** - Automatically finds the appropriate Route53 hosted zone for your domain
2. **API Gateway Creation** - Creates a REST API with Lambda proxy integration for all routes
3. **SSL Certificate** - Requests and validates an ACM certificate using DNS validation
4. **Custom Domain** - Configures API Gateway custom domain with the SSL certificate
5. **DNS Configuration** - Creates Route53 A record pointing to the API Gateway

## Route Configuration

The action creates a **catch-all proxy** that routes:
- `https://api.example.com/` → Your Lambda function
- `https://api.example.com/any/path` → Your Lambda function
- `https://api.example.com/nested/path/here` → Your Lambda function

All requests are forwarded to your Lambda function using the AWS Lambda Proxy Integration format.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Route53 hosted zone for your domain (e.g., `example.com` for `api.example.com`)
- Lambda function deployed and accessible
- Terraform backend configured (S3 + DynamoDB)

## Required AWS Permissions

The action requires the following AWS permissions:

- `apigateway:*` - API Gateway management
- `lambda:*` - Lambda permissions management
- `acm:*` - Certificate management
- `route53:*` - DNS management
- `iam:*` - IAM role management

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌────────────────┐
│   Client        │    │   Route53        │    │  API Gateway   │
│                 │───▶│                  │───▶│                │
│ api.example.com │    │ DNS Resolution   │    │ REST API       │
└─────────────────┘    └──────────────────┘    └────────────────┘
                                                        │
                                                        ▼
                              ┌────────────────────────────────────┐
                              │          Lambda Function           │
                              │                                    │
                              │  Receives all requests via         │
                              │  Lambda Proxy Integration          │
                              └────────────────────────────────────┘
```

## Examples

### Basic Usage
```yaml
- uses: alonch/actions-aws-api-gateway@main
  with: 
    domain: api.example.com
    function: ${{ steps.backend.outputs.arn }}
```

### With Planning
```yaml
- uses: alonch/actions-aws-api-gateway@main
  with: 
    domain: api.example.com
    function: ${{ steps.backend.outputs.arn }}
    action: plan
```

### Destroy Resources
```yaml
- uses: alonch/actions-aws-api-gateway@main
  with: 
    domain: api.example.com
    function: ${{ steps.backend.outputs.arn }}
    action: destroy
```

## Troubleshooting

### Certificate Validation Issues
- Ensure your Route53 hosted zone is properly configured
- Check that the domain ownership can be validated via DNS

### Lambda Permission Issues
- Verify your Lambda function ARN is correct
- Ensure the Lambda function exists and is accessible

### Route53 Issues
- Confirm the hosted zone exists for your root domain
- Check DNS propagation (can take up to 48 hours)

## License

Apache License 2.0