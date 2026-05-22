terraform {
  backend "s3" {
    bucket = "homeserver-terraform-state"
    key    = "pi-backup/terraform.tfstate"
    region = "eu-central-1"
  }
}
