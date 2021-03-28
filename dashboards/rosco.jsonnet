local kpm = import './kubernetes-pod-metrics.jsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Rosco',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='spinnaker-rosco',
)

// Links

.addLinks(
  [
    grafana.link.dashboards(
      icon='info',
      tags=[],
      title='GitHub',
      type='link',
      url='https://github.com/spinnaker/rosco',
    ),
  ]
)

// Templates

.addTemplate(
  grafana.template.datasource(
    'datasource',
    'prometheus',
    '',
  )
)
.addTemplate(
  grafana.template.custom(
    name='spinSvc',
    query='rosco',
    current='rosco',
    hide=2,
  )
)
.addTemplate(
  grafana.template.new(
    name='job',
    datasource='$datasource',
    query='label_values(up{job=~".*$spinSvc.*"}, job)',
    current='All',
    refresh=1,
    includeAll=true,
  )
)
.addTemplate(
  grafana.template.new(
    name='Instance',
    datasource='$datasource',
    query='label_values(up{job=~"$job"}, instance)',
    allValues='.*',
    current='All',
    refresh=1,
    includeAll=true,
    multi=true,
    sort=1,
  )
)

.addRow(
  grafana.row.new(
    title='Key Metrics',
  )
  .addPanel(
    grafana.text.new(
      title='Service Description',
      content="Rosco is Spinnaker's bakery, producing machine images with Hashicorp Packer and rendered manifests with templating engines Helm and Kustomize.",
      span=3,
    )
  )
)

.addRow(
  grafana.row.new(
    title='Additional Metrics',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller 5xx Errors (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_total{job="$job",instance=~"$Instance",status="5xx"}[$__rate_interval])) by (controller, method, statusCode)',
        legendFormat='{{statusCode}}/{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocations by Method (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_total{job=~"$job", instance=~"$Instance"}[$__rate_interval])) by (controller, method)',
        legendFormat='{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocation Latency by Method (rosco, $Instance)',
      datasource='$datasource',
      span=3,
      format='dtdurations',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_seconds_sum{job=~"$job", instance=~"$Instance"}[$__rate_interval])) by (controller, method)\n/\nsum(rate(controller_invocations_seconds_count{job=~"$job", instance=~"$Instance"}[$__rate_interval])) by (controller, method)',
        legendFormat='{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bakes Completed (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_sum{instance=~"$Instance"}[$__rate_interval])) by (region)\n/\nsum(rate(bakesCompleted_seconds_count{instance=~"$Instance"}[$__rate_interval])) by (region)',
        legendFormat='{{region}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Requests and Failures  (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(bakesActive{instance=~"$Instance"}) by (instance)',
        legendFormat='Active/{{instance}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesRequested{instance=~"$Instance"}[$__rate_interval])) by (flavor)',
        legendFormat='Request/{{flavor}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        '-1 * sum(rate(bakesCompleted{instance=~"$Instance",success="false"}[$__rate_interval])) by (region)',
        legendFormat='Failed/{{region}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Machine Metrics',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='JVM Memory Usage ($spinSvc, $Instance)',
      datasource='$datasource',
      span=3,
      format='decbytes',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(jvm_memory_used_bytes{job=~"$job", instance=~"$Instance", area="heap"}) by (id)',
        legendFormat='{{id}}',
      )
    )
  )
)

.addRow(
  kpm
)
