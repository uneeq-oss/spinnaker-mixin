// Grafana Dashboards

{
  grafanaDashboards+:: {
    'application-drilldown.json': (import 'application-drilldown.json'),
    'aws-platform.json': (import 'aws-platform.json'),
    'clouddriver.json': (import 'clouddriver.json'),
    'echo.json': (import 'echo.json'),
    'fiat.json': (import 'fiat.json'),
    'front50.json': (import 'front50.json'),
    'gate.json': (import 'gate.json'),
    'google-platform.json': (import 'google-platform.json'),
    'igor.json': (import 'igor.json'),
    'kubernetes-platform.json': (import 'kubernetes-platform.json'),
    'minimal-spinnaker.json': (import 'minimal-spinnaker.json'),
    'orca.json': (import 'orca.json'),
    'rosco.json': (import 'rosco.json'),
    'spinnaker-key-metrics.json': (import 'spinnaker-key-metrics.json'),
  },
}
