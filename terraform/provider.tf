variable "cloudflare_email" {
  type = string
}

variable "cloudflare_api_key" {
  type = string
}

terraform {
  backend "consul" {
    address = "consul.efthymios.net:8500"
    path    = "terraform/homelab/state"
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 1.4"
    }
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

provider "nomad" {
  address = "http://nomad.efthymios.net:4646"
  region  = "efth"
}

provider "b2" {
  application_key_id = var.backblaze_key_id
  application_key    = var.backblaze_app_key
}
