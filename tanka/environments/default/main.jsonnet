local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = g.dashboard;

local var = g.dashboard.variable.datasource.new('datasource', 'prometheus');

local panel = g.panel.timeSeries.new('Requests / sec')
  + g.panel.timeSeries.queryOptions.withTargets([
    g.query.prometheus.new(
      '$' + var.name,
      '100 * avg(node_memory_Active_bytes) by (instance) / avg(node_memory_MemTotal_bytes) by (instance)',
    ),
  ]);

// Define the dashboard
local myDashboard = dashboard.new("my title")
+ dashboard.withUid("")
+ dashboard.withAnnotations({enable:true})
+ dashboard.withPanels([panel]);

{
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    name: 'test-dashboard1',
    labels: {
      grafana_dashboard: '1',
    },
  },
  data: {
   'test-dashboard-1.json': std.manifestJsonEx(myDashboard,' '),
    }
}
