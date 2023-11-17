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
  description = "Environment"
  type        = string

  validation {
    condition     = var.ENVIRONMENT == "dev" || var.ENVIRONMENT == "rec" || var.ENVIRONMENT == "prod"
    error_message = "Environement must be set to dev, rec or prod"
  }
}

variable "INSTANCE_TYPE" {
  description = "Instance type"
  type        = string
  default     = "t2.micro"
}

variable "DB_NAME" {
  description = "DB Name"
  type        = string
  default     = "prestashopdb"
}

variable "DB_USERNAME" {
  description = "DB Username"
  type        = string
  default     = "AdminDB"
}

variable "DB_PASSWORD" {
  description = "DB Password"
  type        = string
  sensitive   = true
  default     = "A1Very2Strong3Password"
}
