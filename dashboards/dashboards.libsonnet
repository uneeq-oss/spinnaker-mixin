// Grafana Dashboards

{
  grafanaDashboards+:: {
    'clouddriver.json': (import 'clouddriver.jsonnet'),
    'echo.json': (import 'echo.jsonnet'),
    'fiat.json': (import 'fiat.jsonnet'),
    'front50.json': (import 'front50.jsonnet'),
    'gate.json': (import 'gate.jsonnet'),
    'igor.json': (import 'igor.jsonnet'),
    'orca.json': (import 'orca.jsonnet'),
    'rosco.json': (import 'rosco.jsonnet'),
    'spinnaker-application-details.json': (import 'spinnaker-application-details.jsonnet'),
    'spinnaker-aws-platform.json': (import 'spinnaker-aws-platform.jsonnet'),
    'spinnaker-google-platform.json': (import 'spinnaker-google-platform.jsonnet'),
    'spinnaker-key-metrics.json': (import 'spinnaker-key-metrics.jsonnet'),
    'spinnaker-kubernetes-platform.json': (import 'spinnaker-kubernetes-platform.jsonnet'),
    'spinnaker-minimalist.json': (import 'spinnaker-minimalist.jsonnet'),
  },
}
