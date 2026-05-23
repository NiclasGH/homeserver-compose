terraform {
  backend "s3" {
    bucket = "homeserver-terraform-state"
    key    = "homeserver-backup/terraform.tfstate"
    region = "eu-central-1"
  }
}
