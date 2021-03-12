local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Spinnaker Key Metrics',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='spinnaker-key-metrics',
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
  grafana.row.new(
    title='Monitoring Spinnaker, SLA Metrics',
  )
  .addPanel(
    grafana.text.new(
      title='Monitoring Spinnaker, SLA Metrics',
      content='\n# Monitoring Spinnaker, SLA Metrics\n\n[Medium blog by Rob Zienert](https://blog.spinnaker.io/monitoring-spinnaker-sla-metrics-a408754f6b7b)\n\n> What are the key metrics we can track that help quickly answer the question, "Is Spinnaker healthy?"',
      span=3,
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Rate of Echo Triggers & Processed Events',
      datasource='$datasource',
      description='echo.triggers.count tracks the number of CRON-triggered pipeline executions fired. \n\nThis value should be pretty steady, so any significant deviation is an indicator of something going awry (or the addition/retirement of a customer integration).\n\n\necho.pubsub.messagesProcessed is important if you have any PubSub triggers. \n\nYour mileage may vary, but Netflix can alert if any subscriptions drop to zero for more than a few minutes.',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  rate(echo_triggers_count[$__interval])\n)',
        legendFormat='triggers/s',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  rate(echo_events_processed_total[$__interval])\n)',
        legendFormat='events processed/s',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Igor',
      description='pollingMonitor.failed tracks the failure rate of CI/SCM monitor poll cycles. \n\nAny value above 0 is a bad place to be, but is often a result of downstream service availability issues such as Jenkins going offline for maintenance.\n\npollingMonitor.itemsOverThreshold tracks a polling monitor circuit breaker. \n\nAny value over 0 is a bad time, because it means the breaker is open for a particular monitor and it requires manual intervention.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (partition) (\n  pollingMonitor_newItems\n)',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (partition) (\n  pollingMonitor_failed_total\n)',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (partition) (\n  pollingMonitor_itemsOverThreshold\n)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocations Rate',
      description="All Spinnaker services are RPC-based, and as such, the reliability of requests inbound and outbound are supremely important: If the services can’t talk to each other reliably, someone will be having a poor experience.\n\n\nTODO: Add Recording Rules so don't melt Prometheus",
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (container, status) (\n  rate(controller_invocations_total[$__interval])\n )',
        legendFormat='{{ status }} :: {{ container }}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='HTTP RPC Rate',
      datasource='$datasource',
      description='Each service emits metrics for each RPC client that is configured via okhttp.requests.\n\nHaving SLOs — and consequentially, alerts — around failure rate (determined via the succcess tag) and latency for both inbound and outbound RPC requests is, in my mind, mandatory across all Spinnaker services.',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (container, requestHost, status) (\n  rate(okhttp_requests_seconds_count[$__interval])\n)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Clouddriver AWS Cache Drift',
      datasource='$datasource',
      description='cache.drift tracks cache freshness. \n\nYou should group this by agent and region to be granular on exactly what cache collection is falling behind. How much lag is acceptable for your org is up to you, but don’t make it zero.',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'max by (account, agent, region) (cache_drift)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Caching Agent Failures',
      description='It’s OK that there are failures in agents: As stable as we like to think our cloud providers are, it’s still another software system and software will fail. \n\nUnless you see sustained failure, there’s not much to worry about here. \n\nThis is often an indicator of a downstream cloud provider issue.\n\nTODO: Confirm Metric Name',
      span=3,
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Clouddriver Kubernetes / Other Provider Cache',
      description='TODO: Find metric names',
      span=3,
    )
  )
)
