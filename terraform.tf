
terraform {
  required_version = ">= 1.6.6"
  required_providers {
    ise = {
      source  = "CiscoDevNet/ise"
      version = ">= 0.1.12"
    }
    time = {
      source = "hashicorp/time"
      version = "0.10.0"
    }
  }
}

provider "ise" {
  username = "ersadmin1"
  password = "cisco123"
  url      = "https://ise32-3.ise.trappedunderise.com"
}

