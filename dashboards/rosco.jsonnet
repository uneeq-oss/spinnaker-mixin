local jvm = import './jvm-metrics.jsonnet';
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
      span=6,
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Active Bakes (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(bakesActive{instance=~"$Instance"}) by (instance)',
        legendFormat='Active/{{instance}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Request Rate (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesRequested_total{instance=~"$Instance"}[$__rate_interval])) by (flavor)',
        legendFormat='{{flavor}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Failure Rate (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_count{instance=~"$Instance",success="false"}[$__rate_interval])) by (cause, region)',
        legendFormat='{{cause}}/{{region}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Succees Rate (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_count{instance=~"$Instance",success="true"}[$__rate_interval])) by (region)',
        legendFormat='/{{region}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Failure Duration (rosco, $Instance)',
      datasource='$datasource',
      span=3,
      format='dtdurations',
      nullPointMode='null as zero',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_sum{instance=~"$Instance",success="false"}[$__rate_interval])) by (cause,region)\n/\nsum(rate(bakesCompleted_seconds_count{instance=~"$Instance",success="false"}[$__rate_interval])) by (cause,region)',
        legendFormat='{{cause}}/{{region}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Success Duration (rosco, $Instance)',
      datasource='$datasource',
      span=3,
      format='dtdurations',
      nullPointMode='null as zero',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_sum{instance=~"$Instance",success="true"}[$__rate_interval])) by (region)\n/\nsum(rate(bakesCompleted_seconds_count{instance=~"$Instance",success="true"}[$__rate_interval])) by (region)',
        legendFormat='{{region}}',
      )
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
)

.addRow(
  jvm
)

.addRow(
  kpm
)
