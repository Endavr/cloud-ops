provider "aws" {
  region              = var.aws_region
  allowed_account_ids = ["912281739191"]

  default_tags {
    tags = merge(
      {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "Terraform"
      },
      var.additional_tags
    )
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}
