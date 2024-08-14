terraform {
  backend "s3" {
    bucket         = "momo-projects-terraform-states"
    key            = "grouphq/staging/tfstate"
    dynamodb_table = "terraform-states"
    profile        = "grouphq-staging"
    region         = "us-east-2"
  }
}