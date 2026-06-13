terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_lightsail_container_service" "this" {
  name        = var.service_name
  power       = var.power
  scale       = 1
  is_disabled = false
}

resource "aws_lightsail_container_service_deployment_version" "this" {
  count = var.image == "" ? 0 : 1

  service_name = aws_lightsail_container_service.this.name

  container {
    container_name = var.service_name
    image          = var.image
    ports = {
      "8080" = "HTTP"
    }
  }

  public_endpoint {
    container_name = var.service_name
    container_port = 8080

    health_check {
      path                = "/"
      success_codes       = "200-499"
      interval_seconds    = 30
      timeout_seconds     = 5
      healthy_threshold   = 2
      unhealthy_threshold = 2
    }
  }
}
