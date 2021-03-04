local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Igor',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='igor',
)

// Links

.addLinks(
  [
    grafana.link.dashboards(
      icon='info',
      tags=[],
      title='GitHub',
      type='link',
      url='https://github.com/spinnaker/igor',
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
    query='igor',
    current='igor',
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
  grafana.row.new()
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Open',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (name) (\n  max_over_time(resilience4j_circuitbreaker_state{job=~"$job", state=~".*open", instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{name}}',
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
        'sum by (name) (\n  rate(resilience4j_circuitbreaker_failure_rate{job="$job", instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{name}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Half-Open',
      description='The requests/s for Poll Monitor invocations.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (name) (\n  max_over_time(resilience4j_circuitbreaker_state{job="$job", state="half_open", instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{name}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Poll Monitor req/s',
      description='The requests/s for Poll Monitor invocations.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (monitor) (\n  rate(pollingMonitor_pollTiming_seconds_count{job="$job", instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{monitor}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Poll Monitor Latency',
      description='Failed Poll requests per sec by monitor and partition.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (monitor) (rate(pollingMonitor_pollTiming_seconds_sum{job="$job", instance=~"$Instance"}[$__interval]))\n/\nsum by (monitor) (rate(pollingMonitor_pollTiming_seconds_count{job="$job", instance=~"$Instance"}[$__interval]))',
        legendFormat='{{monitor}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Failed Polls',
      description='The requests/s to retrieve docker images by account. This triggers the pipelines.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (monitor, partition) (\n  rate(pollingMonitor_failed_total{job="$job", instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{monitor}} / {{partition}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Docker Images Retrieved',
      description="This gauge tracks the circuit breaker (threshold) for new items (docker, etc).\n\nGenerally the value should always be null or 0.\n\nA positive value indicates the threshold has been exceeded and the circuit breaker tripped. This means Igor will no longer notify Echo of new items and pipelines won't be triggered.\n\nThe circuit breaker can be reset by performing a 'fast-forward' or adjusting the the threshold item limit value and redeploying Igor.\n\nThe threshold can be exceeded due to loss of cache (abnormal) or large influx of new items.",
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (account) (\n  rate(pollingMonitor_docker_retrieveImagesByAccount_seconds_count{job="$job", instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{account}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Items over Threshold',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (monitor, partition) (\n  max_over_time(pollingMonitor_itemsOverThreshold{job="$job", instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{ monitor }} / {{ partition }}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='5xx Controller Invocations',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (controller, method, statusCode) (\n  rate(controller_invocations_total{job=~"$job",status="5xx", instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{statusCode}}/{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocations by Method',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (controller, method) (\n  rate(controller_invocations_total{job=~"$job", instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocation Latency by Method',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (controller, method) (rate(controller_invocations_seconds_sum{job=~"$job", instance=~"$Instance"}[$__interval]))\n/\nsum by (controller, method) (rate(controller_invocations_seconds_count{job=~"$job", instance=~"$Instance"}[$__interval]))',
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

  .addPanel(
    grafana.graphPanel.new(
      title='CPU',
      description='CPU Usage. Average is the average usage across all instaces, max is the highest usage across all instances. As CPU Usage is a sampled metric it is best to view in relation to throttling percentage.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'avg(rate(process_cpu_seconds_total{job=~"$job"}[$__interval]))',
        legendFormat='avg',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'max(rate(process_cpu_seconds_total{job="$job"}[$__interval]))',
        legendFormat='max',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'avg(kube_pod_container_resource_limits_cpu_cores{container="$spinSvc"})',
        legendFormat='Limit',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'avg(kube_pod_container_resource_requests_cpu_cores{container="$spinSvc"})',
        legendFormat='Request',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CPU Throttling',
      description='Percent of the time that the CPU is being throttled. Application may be getting throttled during bursty tasks but overall be well below its CPU limit. Throttling may significantly impact application performance.',
      datasource='$datasource',
      format='percentunit',
      nullPointMode='connected',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'rate(container_cpu_cfs_throttled_periods_total{container="$spinSvc"}[$__interval])\n/\nrate(container_cpu_cfs_periods_total{container="$spinSvc"}[$__interval])',
        legendFormat='{{pod}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Memory',
      description='Memory utilisation. Average is the average usage across all instaces, max is the highest usage across all instances.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'avg(avg_over_time(container_memory_working_set_bytes{container="$spinSvc"}[$__interval]))',
        legendFormat='avg',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'max(max_over_time(container_memory_working_set_bytes{container="$spinSvc"}[$__interval]))',
        legendFormat='max',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'avg(kube_pod_container_resource_limits_memory_bytes{container="$spinSvc"})',
        legendFormat='Limit',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Network',
      description='Average network ingress/egress for the $spinSvc pods.',
      datasource='$datasource',
      nullPointMode='connected',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'avg(\n  sum without (interface) (\n    rate(container_network_receive_bytes_total{pod=~"$spinSvc.*"}[$__interval])\n  )\n)',
        legendFormat='receive',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'avg(\n  sum without (interface) (\n    rate(container_network_transmit_bytes_total{pod=~"$spinSvc.*"}[$__interval])\n  )\n)',
        legendFormat='transmit',
      )
    )
  )
)
