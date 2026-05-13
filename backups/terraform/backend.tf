terraform {
  backend "s3" {
    bucket = "pi-compose-terraform-state"
    key    = "pi-backup/terraform.tfstate"
    region = "eu-central-1"
  }
}
