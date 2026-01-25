terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Por favor, altere para a sua região de preferência
  region = "us-east-1"
}
