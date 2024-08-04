terraform {
  backend "s3" {
    bucket = "netflix.latest.1"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}
