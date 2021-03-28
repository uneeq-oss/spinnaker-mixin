local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Spinnaker Application Details',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='spinnaker-application-details',
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
  grafana.template.new(
    name='Application',
    datasource='$datasource',
    query='label_values(stage_invocations_total{spinSvc="orca"}, application)',
    allValues='.*',
    current='All',
    refresh=2,
    includeAll=true,
    multi=true,
    sort=1,
  )
)

.addRow(
  grafana.row.new()
  .addPanel(
    grafana.graphPanel.new(
      title='Active Stages by Application (orca, $Application)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_total{spinSvc="$spinSvc", application=~"$Application"}[$__rate_interval])) by (application, type)',
        legendFormat='{{application}}/{{type}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Pushed Messages by Application (orca, $Application)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(queue_pushed_messages_total{spinSvc="$spinSvc", application=~"$Application"}[$__rate_interval])) by (application)',
        legendFormat='{{application}}',
      )
    )
  )


  .addPanel(
    grafana.graphPanel.new(
      title='$Application Pipelines Triggered (echo)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(pipelines_triggered_total{spinSvc=~"echo", application=~"$Application"}[$__rate_interval])) by (name, application)',
        legendFormat='{{name}}({{application}})',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Bake Requests and Failures (rosco)',
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
        'sum(rate(bakesRequested_total[$__rate_interval])) by (flavor)',
        legendFormat='Request({{flavor}})',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Bakes Completed (rosco)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        '-1 * sum(rate(bakesCompleted_seconds_count{success="false"}[$__rate_interval])) by (region)',
        legendFormat='Failed {{region}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_sum[$__rate_interval]) / 1000000000) by (region)\n/\nsum(rate(bakesCompleted_seconds_count[$__rate_interval])) by (region)',
        legendFormat='{{region}}',
      )
    )
  )


  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Open',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(resilience4j_circuitbreaker_state{state=~".*open"}) by (name, spinSvc)',
        legendFormat='{{spinSvc}}-{{name}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Failure Rate',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(resilience4j_circuitbreaker_failure_rate[$__rate_interval])) by (name, spinSvc)',
        legendFormat='{{spinSvc}}-{{name}}',
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
        'sum(resilience4j_circuitbreaker_state{state="half_open"}) by (name, spinSvc)',
        legendFormat='{{spinSvc}}-{{name}}',
      )
    )
  )
)
