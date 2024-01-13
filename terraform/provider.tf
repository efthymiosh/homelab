terraform {
  backend "consul" {
    address = "snu.int.efhd.dev:8501"
    scheme  = "https"
    path    = "terraform/homelab/state"
    ca_file = "./resources/intermediate-ca.pem"
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.23"
    }
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.8"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    consul = {
      source = "hashicorp/consul"
      version = "~> 2.20"
    }
  }
}

provider "nomad" {
  address = "http://nomad.efhd.dev:4646"
  region  = "efth"
}

provider "consul" {
  address = "http://snu.int.efhd.dev:8501"
  scheme  = "https"
  ca_file = "./resources/intermediate-ca.pem"
}
