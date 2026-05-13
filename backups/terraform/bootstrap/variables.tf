variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-central-1"
}

variable "state_bucket_name" {
  description = "Terraform state bucket name"
  type        = string
}

variable "tags" {
  description = "Bucket tags"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}
