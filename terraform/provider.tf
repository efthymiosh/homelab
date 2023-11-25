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
      version = "~> 2.0"
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
  address = "http://consul.efhd.dev:8500"
}
