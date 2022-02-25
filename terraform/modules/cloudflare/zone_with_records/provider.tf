terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
  experiments = [
    module_variable_optional_attrs
  ]
}
