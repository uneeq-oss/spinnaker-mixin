local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Orca',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='orca',
)

// Links

.addLinks(
  [
    grafana.link.dashboards(
      icon='info',
      tags=[],
      title='GitHub',
      type='link',
      url='https://github.com/spinnaker/orca',
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
    query='orca',
    current='orca',
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
      title='5xx Invocation Errors (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_total{job=~"$job", instance=~"$Instance", status="5xx"}[$__interval])) by (controller, method, status)',
        legendFormat='{{statusCode}}/{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Stage Durations > 5m per Time-Bucket/Platform (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_duration_total{job=~"$job", instance=~"$Instance", bucket!="lt5m"}[$__interval])) by (stageType, cloudProvider, bucket)',
        legendFormat='{{bucket}}/{{cloudProvider}}/{{stageType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Ok Http Calls by Status Code (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(okhttp_requests_seconds_count{job=~"$job",instance=~"$Instance"}[$__interval])) by (statusCode)',
        legendFormat='{{statusCode}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Ok Http Calls Latency by Request Host (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(okhttp_requests_seconds_sum{job=~"$job", instance=~"$Instance"}[$__interval])) by (requestHost)\n/\nsum(rate(okhttp_requests_seconds_count{job="$job", instance=~"$Instance"}[$__interval])) by (requestHost)',
        legendFormat='{{requestHost}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocations by Method (orca, $Instance)',
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
      title='Controller Invocation Latency by Method (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_seconds_sum{job=~"$job", instance=~"$Instance"}[$__interval])) by (controller, method)\n/\nsum(rate(controller_invocations_total{job=~"$job", instance=~"$Instance"}[$__interval])) by (controller, method)',
        legendFormat='{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Active Stages per Type/Platform (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_total{job=~"$job", instance=~"$Instance"}[$__interval])) by (cloudProvider, type)',
        legendFormat='{{type}}/{{cloudProvider}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Stages Completed per Type/Platform (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_duration_total{job=~"$job", instance=~"$Instance"}[$__interval])) by (cloudProvider, stageType)',
        legendFormat='{{stageType}}/{{cloudProvider}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Blocked Queues (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(threadpool_blockingQueueSize{job=~"$job", instance=~"$Instance"}[$__interval])) by (id)',
        legendFormat='{{id}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Zombie Queues (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (application) (queue_zombies_total{job=~"$job", instance=~"$Instance"})',
        legendFormat='{{ application }}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Active Threads (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(threadpool_activeCount{job=~"$job", instance=~"$Instance"}) by (id)',
        legendFormat='{{id}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='ThreadPool Size (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(threadpool_poolSize{job=~"$job", instance=~"$Instance"}) by (id)',
        legendFormat='{{id}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Queue Depth (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(queue_depth{job=~"$job", instance=~"$Instance"}) by (instance)',
        legendFormat='Queued',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(queue_ready_depth{job=~"$job", instance=~"$Instance"}) by (instance)',
        legendFormat='Ready',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(queue_unacked_depth{job=~"$job", instance=~"$Instance"}) by (instance)',
        legendFormat='In-Process',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Queue Errors (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(queue_retried_messages_total{job=~"$job", instance=~"$Instance"}[$__interval])) by (job)',
        legendFormat='Retried',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(queue_dead_messages_total{job=~"$job", instance=~"$Instance"}[$__interval])) by (job)',
        legendFormat='Dead',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(queue_orphaned_messages{job=~"$job", instance=~"$Instance"}[$__interval])) by (job)',
        legendFormat='Orphaned',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Message Lag Time (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'rate(queue_message_lag_seconds_count{job=~"$job", instance=~"$Instance"}[$__interval])',
        legendFormat='messages {{ instance }}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'rate(queue_message_lag_seconds_sum{job=~"$job", instance=~"$Instance"}[$__interval])\n/\nrate(queue_message_lag_seconds_count{job=~"$job", instance=~"$Instance"}[$__interval])',
        legendFormat='lag time {{ instance }}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Pushed Message Summary (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(queue_pushed_messages_total{job=~"$job", instance=~"$Instance"}[$__interval])) by (instance)',
        legendFormat='Pushed/{{ instance }}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(queue_acknowledged_messages_total{instance=~"$Instance"}[$__interval])) by (instance)',
        legendFormat='Acknowledged/{{ instance }}',
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
