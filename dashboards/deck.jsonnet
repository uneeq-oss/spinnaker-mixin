local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Deck',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='deck',
)

// Links

.addLinks(
  [
    grafana.link.dashboards(
      icon='info',
      tags=[],
      title='GitHub',
      type='link',
      url='https://github.com/spinnaker/deck',
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
    query='deck',
    current='echo',
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
      content='Deck is the browser-based UI.\n\nIt is built on Apache2 which does not natively serve a Prometheus metrics endpoint.',
      span=3,
    )
  )
)

.addRow(
  grafana.row.new(
    title='Machine Metrics',
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
