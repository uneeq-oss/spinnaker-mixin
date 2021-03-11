local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Spinnaker Minimalist',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='spinnaker-minimalist',
)

// Templates

.addTemplate(
  grafana.template.datasource(
    'datasource',
    'prometheus',
    '',
  )
)

.addRow(
  grafana.row.new()
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Open',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(resilience4j_circuitbreaker_state{state="open"}) by (job, metricGroup, metricType)',
        legendFormat='{{ job }}/{{metricGroup}}({{metricType}})',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Half-Open',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(resilience4j_circuitbreaker_state{state="half_open"}) by (job, metricGroup, metricType)',
        legendFormat='{{ job }} /{{metricType}}({{metricGroup}})',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='5xx Invocation Errors',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="clouddriver",status="5xx"}[$__interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Clouddriver/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="echo",status="5xx"}[$__interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Echo/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="fiat",status="5xx"}[$__interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Fiat/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="front50",status="5xx"}[$__interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Front50/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="gate",status="5xx"}[$__interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Gate/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="igor",status="5xx"}[$__interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Igor/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="orca",status="5xx"}[$__interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Orca/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="rosco",status="5xx"}[$__interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Rosco/{{statusCode}}/{{controller}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Active Stages per Type/Platform (orca)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_total[$__interval])) by (instance, type, cloudProvider)',
        legendFormat='{{type}}/{{cloudProvider}}/{{instance}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Completed Stages per Type/Platform (orca)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_total[$__interval])) by (cloudProvider, type)',
        legendFormat='{{cloudProvider}} :: {{type}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Stage Duration > 5m per Time-Bucket/Platform (orca)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_duration_total{bucket!="lt5m"}[$__interval])) by (cloudProvider, percentile)',
        legendFormat='{{percentile}}/{{cloudProvider}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Pipelines Triggered (echo)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(pipelines_triggered_total[$__interval])) by (application,monitor)',
        legendFormat='{{application}} :: {{ monitor }}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Activity (rosco)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(bakesActive)',
        legendFormat='Active',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesRequested[$__interval])) by (flavor)',
        legendFormat='Request({{flavor}})',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        '-1 * sum(rate(bakesCompleted{success="false"}[$__interval])) by (region)',
        legendFormat='Failed {{region}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Item Cache Size (front50)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(storageServiceSupport_cacheSize) by (objectType)',
        legendFormat='{{objectType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Execution Count (clouddriver)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(executionCount_total[$__interval])) by (instance)',
        legendFormat='{{instance}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Execution Latency (clouddriver)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(executionTime_seconds_sum[$__interval])) by (instance) / sum(rate(executionTime_seconds_count[$__interval])) by (instance)',
        legendFormat='{{instance}}',
      )
    )
  )
)
