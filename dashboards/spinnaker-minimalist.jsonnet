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
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="clouddriver",status="5xx"}[$__rate_interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Clouddriver/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="echo",status="5xx"}[$__rate_interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Echo/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="fiat",status="5xx"}[$__rate_interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Fiat/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="front50",status="5xx"}[$__rate_interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Front50/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="gate",status="5xx"}[$__rate_interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Gate/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="igor",status="5xx"}[$__rate_interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Igor/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="orca",status="5xx"}[$__rate_interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Orca/{{statusCode}}/{{controller}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(controller_invocations_total{container="rosco",status="5xx"}[$__rate_interval])) by (controller, statusCode), "controller", "$1", "controller", "(.*)Controller")',
        legendFormat='Rosco/{{statusCode}}/{{controller}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Active Stages per Type/Platform (orca)',
      datasource='$datasource',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_total[$__rate_interval])) by (type, cloudProvider)',
        legendFormat='{{type}}/{{cloudProvider}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Completed Stages per Type/Platform (orca)',
      datasource='$datasource',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_total[$__rate_interval])) by (cloudProvider, type)',
        legendFormat='{{cloudProvider}} :: {{type}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Stage Duration (log2) per Platform (orca)',
      description='Not all AWS stages have "cloudProvider" label. Override missing options to "aws(override)"',
      datasource='$datasource',
      format='dtdurations',
      logBase1Y='2',
      nullPointMode='null as zero',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_duration_seconds_sum[$__rate_interval])) by (cloudProvider)\n/\nsum(rate(stage_invocations_duration_seconds_count[$__rate_interval])) by (cloudProvider)',
        legendFormat='{{cloudProvider}}',
      )
    )
    .addOverride(
      matcher={
        id: 'byRegexp',
        options: 'Value',
      },
      properties=[
        {
          id: 'displayName',
          value: 'aws(override)',
        },
      ],
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Pipelines Triggered (echo)',
      datasource='$datasource',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(pipelines_triggered_total[$__rate_interval])) by (application,monitor)',
        legendFormat='{{application}} :: {{ monitor }}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Active Bakes (rosco)',
      datasource='$datasource',
    )
    .addTarget(
      grafana.prometheus.target(
        'bakesActive',
        legendFormat='Active',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Request and Completion Rates (rosco)',
      datasource='$datasource',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesRequested_total[$__rate_interval])) by (flavor)',
        legendFormat='Requested/{{flavor}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_count{success="false"}[$__rate_interval])) by (region)',
        legendFormat='Failure/{{region}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_count{success="true"}[$__rate_interval])) by (region)',
        legendFormat='Success/{{region}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Item Cache Size (front50)',
      datasource='$datasource',
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
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(executionCount_total[$__rate_interval])) by (instance)',
        legendFormat='{{instance}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Execution Latency (clouddriver)',
      datasource='$datasource',
      format='dtdurations',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(executionTime_seconds_sum[$__rate_interval])) by (instance) / sum(rate(executionTime_seconds_count[$__rate_interval])) by (instance)',
        legendFormat='{{instance}}',
      )
    )
  )
)
