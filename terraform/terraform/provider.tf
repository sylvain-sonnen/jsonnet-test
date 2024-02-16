terraform {
  required_providers {
    jsonnet = {
      source  = "alxrem/jsonnet"
      version = ">= 2.2.0"
    }
    grafana = {
      source = "grafana/grafana"
      version = "2.11.0"
    }
  }
}

provider "jsonnet" {
  jsonnet_path = "../jsonnet/vendor"
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth
}
