terraform {
  backend "s3" {
    bucket         = "netflix.latest.1"
    key            = "terraform/state.tfstate"
    region          = "ap-south-1"
  }
}
