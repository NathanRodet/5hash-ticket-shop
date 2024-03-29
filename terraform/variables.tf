# This variable file is used to define the variables used in the Terraform configuration.

# Global

variable "ENVIRONMENT" {
  type        = string
  sensitive   = false
  description = "Environment name."

  validation {
    condition     = var.ENVIRONMENT == "dev" || var.ENVIRONMENT == "rec" || var.ENVIRONMENT == "prod"
    error_message = "Environement must be set to dev, rec or prod"
  }
}

variable "LOCATION" {
  type        = string
  sensitive   = false
  description = "Region name."
}

variable "RESOURCE_GROUP_NAME" {
  type        = string
  sensitive   = false
  description = "Resource group name."
}

variable "PROJECT_NAME" {
  type        = string
  sensitive   = false
  description = "Project name."
}

# MySQL Database
variable "MYSQL_ADMIN_LOGIN" {
  type        = string
  sensitive   = false
  description = "Admin login."
}

variable "MYSQL_ADMIN_PASSWORD" {
  type        = string
  sensitive   = false
  description = "Admin password."
}

