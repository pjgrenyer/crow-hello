variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "service_name" {
  type    = string
  default = "crow-hello"
}

variable "power" {
  type        = string
  default     = "nano"
  description = "nano | micro | small | medium | large"
}

variable "image" {
  type        = string
  default     = ""
  description = "Image ref pushed via `aws lightsail push-container-image`, e.g. ':crow-hello.crow-hello.1'. Leave empty on first apply, then set after pushing."
}
