variable "ENVIRONEMENT" {
  description = "Environement"
  type = string
  default = "dev"

  validation {
    condition = contains(["dev", "rec", "prod"], var.ENVIRONEMENT)
    error_message = "Environement must be set to dev, rec or prod"
  }
} 

variable "IMAGE_ID" {
  description = "Image ID"
  type = string
  default = "ami-0d5eff06f840b45e9"
}

variable "INSTANCE_TYPE" {
  description = "Instance type"
  type = string
  default = "t2.micro"
}