local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Front50',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='front50',
)

// Links

.addLinks(
  [
    grafana.link.dashboards(
      icon='info',
      tags=[],
      title='GitHub',
      type='link',
      url='https://github.com/spinnaker/front50',
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
    query='front50',
    current='front50',
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
      content='Front50 is the system of record for all Spinnaker metadata, including: application, pipeline and service account configurations.\n\nAll metadata is durably stored and served out of an in-memory cache.',
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
      title='Resilience4J Open (front50, $Instance)',
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
      title='Resilience4J Failure Rate (front50, $Instance)',
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
      title='Resilience4J Half-Open (front50, $Instance)',
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
      title='5xx Invocation Errors by Method (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_total{job=~"$job", instance=~"$Instance", status="5xx"}[$__interval])) by (controller, method, statusCode)',
        legendFormat='{{statusCode}}/{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Cache Refreshes / Minute  (negative are scheduled) (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(storageServiceSupport_autoRefreshTime_seconds_sum{instance=~"$Instance"}[$__interval])) by (objectType)',
        legendFormat='force/{{objectType}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        '-1 * (sum(rate(storageServiceSupport_scheduledRefreshTime_seconds_sum{instance=~"$Instance"}[$__interval])) by (objectType))',
        legendFormat='{{objectType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocation by Method (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_total{job=~"$job", instance=~"$Instance"}[$__interval])) by (controller, method)',
        legendFormat='{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Item Cache Size (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(storageServiceSupport_cacheSize{instance=~"$Instance"}) by (objectType)',
        legendFormat='{{objectType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocation Latency by Method (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_seconds_sum{job=~"$job", instance=~"$Instance"}[$__interval])) by (controller, method)\n/ \nsum(rate(controller_invocations_seconds_count{job=~"$job", instance=~"$Instance"}[$__interval])) by (controller, method)',
        legendFormat='{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Item Cache Adds (+) and Removes (-) (front50, $Instance)',
      aliasColors={
        'del APPLICATION': '#7EB26D',
        'del APPLICATION_PERMISSION': '#EAB839',
        'del NOTIFICATION': '#6ED0E0',
        'del PIPELINE': '#EF843C',
        'del PROJECT': '#E24D42',
        'del SERVICE_ACCOUNT': '#1F78C1',
        'del SNAPSHOT': '#BA43A9',
        'del STRATEGY': '#705DA0',
      },
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(storageServiceSupport_numAdded_total{instance=~"$Instance"}[$__interval])) by (objectType)',
        legendFormat='add {{objectType}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        '-1 * sum(rate(storageServiceSupport_numRemoved_total{instance=~"$Instance"}[$__interval])) by (objectType)',
        legendFormat='del {{objectType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Google Storage Service Invocations (front50, $Instance)',
      description='TODO: Swap for relevant SQL metrics?',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(front50:google:storage:invocation__count_total{instance=~"$Instance"}[$__interval])) by (method)',
        legendFormat='{{method}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Item Cache Updates (front50, $Instance)',
      description='TODO: Swap for relevant SQL metrics?',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(storageServiceSupport_numUpdated_total{instance=~"$Instance"}[$__interval])) by (objectType)',
        legendFormat='{{objectType}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Google Storage Service Invocation Latency (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(front50:google:storage:invocation__totalTime_total{instance=~"$Instance"}[$__interval])) by (method) / sum(rate(front50:google:storage:invocation__count_total{instance=~"$Instance"}[$__interval])) by (method)',
        legendFormat='{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Item Cache Age (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'avg by (objectType) (storageServiceSupport_cacheAge{instance=~"$Instance"})',
        legendFormat='{{objectType}}',
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
