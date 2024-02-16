data "jsonnet_file" "dashboard" {
  ext_str = {
    ext_var = " this is external"
  }
  source = "../jsonnet/dashboard.jsonnet"
}

resource "grafana_dashboard" "demo_dashboard" {
  config_json = data.jsonnet_file.dashboard.rendered
}
