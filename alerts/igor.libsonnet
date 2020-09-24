{
  prometheusAlerts+:: {
    groups+: [{
      name: 'igor',
      rules: [
        {
          alert: 'PollingMonitorItemsOverThreshold',
          expr: 'sum by (monitor, partition) (pollingMonitor_itemsOverThreshold) > 0',
          'for': '5m',
          labels: {
            severity: 'critical',
          },
          annotations: {
            summary: 'Polling monitor item threshold exceeded.',
            description: '{{ $labels.monitor }} polling monitor for {{ $labels.partition }} threshold exceeded, preventing pipeline triggers.',
            runbook_url: 'https://kb.armory.io/s/article/Hitting-Igor-s-caching-thresholds',
          },
        },
      ],
    }],
  },
}
