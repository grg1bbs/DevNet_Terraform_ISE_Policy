
terraform {
  required_version = ">= 1.6.6"
  required_providers {
    ise = {
      source  = "CiscoDevNet/ise"
      version = ">= 0.1.14"
    }
    time = {
      source = "hashicorp/time"
      version = "0.10.0"
    }
  }
}

provider "ise" {
  username = "<ers admin>"
  password = "<password>"
  url      = "<Primary PAN FQDN>"
}

