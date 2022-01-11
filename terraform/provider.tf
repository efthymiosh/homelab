variable "cloudflare_email" {
  type = string
}

variable "cloudflare_api_key" {
  type = string
}

terraform {
  backend "consul" {
    address = "consul.efthymios.net"
    path    = "terraform/homelab/state"
  }

  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}
