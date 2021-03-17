local kpm = import './kubernetes-pod-metrics.jsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Gate',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='gate',
)

// Links

.addLinks(
  [
    grafana.link.dashboards(
      icon='info',
      tags=[],
      title='GitHub',
      type='link',
      url='https://github.com/spinnaker/gate',
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
    query='gate',
    current='gate',
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
      content='This service provides the Spinnaker REST API, servicing scripting clients as well as all actions from Deck. The REST API fronts the following services:\n\n- Clouddriver\n-Front50\n-Igor\n-Orca',
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
      title='Resilience4J Open (gate, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(resilience4j_circuitbreaker_state{job=~"$job", state=~".*open", instance=~"$Instance"}) by (name)',
        legendFormat='{{name}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Failure Rate (gate, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(resilience4j_circuitbreaker_failure_rate{job=~"$job", instance=~"$Instance"}[$__interval])) by (name)',
        legendFormat='{{ name }}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Half-Open (gate, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(resilience4j_circuitbreaker_state{job=~"$job", state="half_open", instance=~"$Instance"}) by (name)',
        legendFormat='{{name}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Rate Limit Throttling (gate, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'rate(rateLimitThrottling_total{instance=~"$Instance"}[$__interval])',
        legendFormat='',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='5xx/429 Controller Invocations (gate, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_seconds_count{job=~"$job", instance=~"$Instance",status="5xx"}[$__interval])) by (controller, method, statusCode)',
        legendFormat='{{statusCode}}/{{controller}}/{{method}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_seconds_count{job=~"$job", instance=~"$Instance",statusCode="429"}[$__interval])) by (controller, method, statusCode)',
        legendFormat='{{statusCode}}/{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocations by Method (gate, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_seconds_count{job=~"$job", instance=~"$Instance"}[$__interval])) by (controller, method)',
        legendFormat='{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocation Latency by Method (gate, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_seconds_sum{job=~"$job", instance=~"$Instance"}[$__interval])) by (controller, method)\n/\nsum(rate(controller_invocations_seconds_count{job=~"$job", instance=~"$Instance"}[$__interval])) by (controller, method)',
        legendFormat='{{controller}}/{{method}}',
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
