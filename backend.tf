terraform {
  backend "s3" {
    bucket = "terraform-bucket-sreekanthv.com"
    key    = "terraform-project.tfstate"
    region = "us-east-2"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}