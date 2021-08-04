local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.row.new(
  title='JVM Metrics',
)

.addPanel(
  grafana.graphPanel.new(
    title='JVM Memory Usage',
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

.addPanel(
  grafana.graphPanel.new(
    title='JVM GC Average Pause Seconds',
    datasource='$datasource',
    span=3,
    format='dtdurations',
  )
  .addTarget(
    grafana.prometheus.target(
      'sum by (instance) (jvm_gc_pause_seconds_sum{job=~"$job", instance=~"$Instance"}) \n / \n sum by (instance) (jvm_gc_pause_seconds_count{job=~"$job", instance=~"$Instance"})',
      legendFormat='{{instance}}',
    )
  )
)

.addPanel(
  grafana.graphPanel.new(
    title='JVM GC Maximum Pause Seconds',
    datasource='$datasource',
    span=3,
    format='dtdurations',
  )
  .addTarget(
    grafana.prometheus.target(
      'max by (instance) (jvm_gc_pause_seconds_max{job=~"$job", instance=~"$Instance"})',
      legendFormat='{{instance}}',
    )
  )
)

.addPanel(
  grafana.graphPanel.new(
    title='JVM Threads',
    datasource='$datasource',
    span=3,
    fill=0,
  )
  .addTarget(
    grafana.prometheus.target(
      'max_over_time(jvm_threads_live_threads{job=~"$job", instance=~"$Instance"}[$__rate_interval])',
      legendFormat='{{instance}}',
      interval='1m',
    )
  )
)
