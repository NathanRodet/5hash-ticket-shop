variable "AWS_ACCESS_KEY" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "AWS_SECRET_KEY" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "AWS_REGION" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1"
}

variable "ENVIRONMENT" {
  description = "Environement"
  type        = string

  validation {
    condition     = var.ENVIRONMENT == "dev" || var.ENVIRONMENT == "rec" || var.ENVIRONMENT == "prod"
    error_message = "Environement must be set to dev, rec or prod"
  }
}

variable "IMAGE_ID" {
  description = "Image ID"
  type        = string
  default     = "ami-0d5eff06f840b45e9"
}

variable "INSTANCE_TYPE" {
  description = "Instance type"
  type        = string
  default     = "t2.micro"
}


