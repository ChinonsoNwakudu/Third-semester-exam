terraform {
  backend "s3" {
    bucket = "jenkins-exampro"
    region = "us-east-1"
    key    = "jen-keys/terraform.tfstate"
  }
}