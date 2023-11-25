terraform {
  backend "consul" {
    address = "consul.efthymios.net:8500"
    path    = "terraform/homelab/state"
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 1.4"
    }
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.8"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "nomad" {
  address = "http://nomad.efthymios.net:4646"
  region  = "efth"
}
