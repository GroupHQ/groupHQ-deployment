provider "aws" {
  region  = "us-east-2"
  profile = "grouphq-staging"

  assume_role {
    role_arn = "arn:aws:iam::010438489417:role/Shared_Services_GroupHQ_Staging_Admin"
  }
}

