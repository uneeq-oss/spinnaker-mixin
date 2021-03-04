// Grafana Dashboards

{
  grafanaDashboards+:: {
    'application-drilldown.json': (import 'application-drilldown.json'),
    'aws-platform.json': (import 'aws-platform.json'),
    'clouddriver.json': (import 'clouddriver.jsonnet'),
    'echo.json': (import 'echo.jsonnet'),
    'fiat.json': (import 'fiat.jsonnet'),
    'front50.json': (import 'front50.jsonnet'),
    'gate.json': (import 'gate.jsonnet'),
    'google-platform.json': (import 'google-platform.json'),
    'igor.json': (import 'igor.jsonnet'),
    'kubernetes-platform.json': (import 'kubernetes-platform.json'),
    'minimal-spinnaker.json': (import 'minimal-spinnaker.json'),
    'orca.json': (import 'orca.jsonnet'),
    'rosco.json': (import 'rosco.jsonnet'),
    'spinnaker-key-metrics.json': (import 'spinnaker-key-metrics.json'),
  },
}
