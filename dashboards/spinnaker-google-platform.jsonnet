local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Spinnaker GCP Platform',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='spinnaker-gcp-platform',
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
    name='GcpRegion',
    datasource='$datasource',
    query='clouddriver:google:api__count',
    allValues='.*',
    current='All',
    regex='/.*region="([^"]+).*/',
    refresh=2,
    includeAll=true,
    sort=1,
  )
)
.addTemplate(
  grafana.template.new(
    name='ClouddriverInstance',
    datasource='$datasource',
    query='label_values(clouddriver:google:api__count, instance)',
    allValues='.*',
    current='All',
    refresh=2,
    includeAll=true,
    sort=1,
  )
)
.addTemplate(
  grafana.template.new(
    name='Front50Instance',
    datasource='$datasource',
    query='label_values(front50:google:storage:invocation__count, instance)',
    allValues='.*',
    current='All',
    refresh=2,
    includeAll=true,
    sort=1,
  )
)

.addRow(
  grafana.row.new(
    title='API Errors',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='GCP API Failures by Resource (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(label_replace(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",status!="2xx"}[$__interval]), "resource", "$1", "api", "compute.(.*)\\\\..*")) by (resource, statusCode)',
        legendFormat='{{statusCode}}/{{resource}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='GCP API Failures by Region (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",status!="2xx", scope="regional"}[$__interval])) by (region, statusCode)',
        legendFormat='{{statusCode}}/{{region}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(label_replace(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",status!="2xx",scope="zonal"}[$__interval]), "zoneRegion", "$1", "zone", "(.*)-.")) by (zoneRegion, statusCode)',
        legendFormat='{{statusCode}}/{{zoneRegion}}+',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",status!="2xx",scope="global"}[$__interval])) by (zone, statusCode)',
        legendFormat='{{statusCode}}/global',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Google Storage Failures By Method (front50, $Front50Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(front50:google:storage:invocation__count_total{instance=~"$Front50Instance",status!="2xx"}[$__interval])) by (method, statusCode)',
        legendFormat='{{statusCode}}/{{method}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Google Storage Retry Failures by Method (front50, $Front50Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(front50:google:storage:invocation__count_total{instance=~"$Front50Instance",status!="2xx"}[$__interval])) by (method, statusCode)',
        legendFormat='{{statusCode}}/{{method}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(front50:google:safeRetry__count_total{instance=~"$Front50Instance", success!="true"}[$__interval])) by (action)',
        legendFormat='{{action}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='API Call Summary',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='GCP API Calls by Resource (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(label_replace(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance"}[$__interval]), "resource", "$1", "api", "compute.(.*)\\\\..*")) by (resource)',
        legendFormat='{{resource}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(label_replace(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance"}[$__interval]), "resource", "$1", "api", "compute.(.*)\\\\..*")) by (resource, status, statusCode)',
        legendFormat='{{resource}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='GCP API Calls by Region (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",scope="regional"}[$__interval])) by (region)',
        legendFormat='{{region}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(label_replace(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",scope="zonal"}[$__interval]), "zoneRegion", "$1", "zone", "(.*)-.")) by (zoneRegion)',
        legendFormat='{{zoneRegion}}+',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",scope="global"}[$__interval])) by (zone)',
        legendFormat='global',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Global API Calls',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Global GCP API Calls (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",scope="global"}[$__interval])) by (api), "api", "$1", "api", "compute.(.*)")',
        legendFormat='{{api}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Global GCP API Latency (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(clouddriver:google:api__totalTime_total{instance=~"$ClouddriverInstance",scope="global"}[$__interval])) by (api) / sum(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",scope="global"}[$__interval])) by (api), "api", "$1", "api", "compute.(.*)")',
        legendFormat='{{api}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Regional API Calls',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Regional GCP API Calls in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",scope="regional",region=~"$GcpRegion"}[$__interval])) by (api), "api", "$1", "api", "compute.(.*)")',
        legendFormat='{{api}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Regional GCP API Latency in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(clouddriver:google:api__totalTime_total{instance=~"$ClouddriverInstance",scope="regional",region=~"$GcpRegion"}[$__interval])) by (api) / sum(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",scope="regional",region=~"$GcpRegion"}[$__interval])) by (api), "api", "$1", "api", "compute.(.*)")',
        legendFormat='{{api}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Zonal API Calls',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Zonal GCP API in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(label_replace(sum(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",scope="zonal",zone=~".*$GcpRegion.*"}[$__interval])) by (zone, api), "api", "$1", "api", "compute.(.*)"), "cell", "$1", "zone", ".*-(.)")',
        legendFormat='{{api}}/{{cell}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Zonal GCP API Latency in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(clouddriver:google:api__totalTime_total{instance=~"$ClouddriverInstance",scope="zonal",zone=~".*$GcpRegion.*"}[$__interval])) by (api, zone) / sum(rate(clouddriver:google:api__count_total{instance=~"$ClouddriverInstance",scope="zonal", zone=~".*$GcpRegion.*"}[$__interval])) by (api, zone), "api", "$1", "api", "compute.(.*)")',
        legendFormat='{{api}}/{{zone}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Batch Calls',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='GCP Batch Size (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(clouddriver:google:batchSize{instance=~"$ClouddriverInstance"}[$__interval])) by (context), "context", "$1$2", "context", "(.*)Caching(.*)")',
        legendFormat='{{context}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='GCP Batch Count (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(clouddriver:google:batchExecute__count_total{instance=~"$ClouddriverInstance"}[$__interval])) by (context), "context", "$1$2", "context", "(.*)Caching(.*)")',
        legendFormat='{{context}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='GCP Batch Latency (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(rate(clouddriver:google:batchExecute__totalTime_total{instance=~"$ClouddriverInstance"}[$__interval]) / rate(clouddriver:google:batchExecute__count_total{instance=~"$ClouddriverInstance"}[$__interval]), "context", "$1$2", "context", "(.*)Caching(.*)")',
        legendFormat='{{context}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='GCP Operations Outcome',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Successful GCP Operations (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:operationWaits__count_total{instance=~"$ClouddriverInstance",status="DONE"}[$__interval])) by (basePhase)',
        legendFormat='{{basePhase}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Failed GCP Operations (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:operationWaits__count_total{instance=~"$ClouddriverInstance",status!="DONE"}[$__interval])) by (basePhase, scope) ',
        legendFormat='{{scope}}/{{basePhase}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Waiting GCP Operations',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Global GCP Operation Waiting (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:operationWaits__totalTime_total{instance=~"$ClouddriverInstance",scope="global"}[$__interval])) by (basePhase) / sum(rate(clouddriver:google:operationWaits__count_total{instance=~"$ClouddriverInstance",scope="global"}[$__interval])) by (basePhase) ',
        legendFormat='{{basePhase}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Regional GCP Operation Waiting in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:operationWaits__totalTime_total{instance=~"$ClouddriverInstance",scope="regional",region=~"$GcpRegion"}[$__interval])) by (region, basePhase) / sum(rate(clouddriver:google:operationWaits__count_total{instance=~"$ClouddriverInstance",scope="regional",region=~"$GcpRegion"}[$__interval])) by (region, basePhase) ',
        legendFormat='{{basePhase}}//{{region}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Zonal GCP Operation Waiting in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(label_replace(rate(clouddriver:google:operationWaits__totalTime_total{instance=~"$ClouddriverInstance",scope="zonal",zone=~".*$GcpRegion.*"}[$__interval]), "cell", "$1", "zone", ".*-(.)")) by (basePhase, cell) / sum(label_replace(rate(clouddriver:google:operationWaits__count_total{instance=~"$ClouddriverInstance",scope="zonal",zone=~".*$GcpRegion.*"}[$__interval]), "cell", "$1", "zone", ".*-(.)")) by (basePhase, cell) ',
        legendFormat='{{basePhase}}/{{cell}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Started GCP Operations',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Global GCP Operations Started (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:operationWaitRequests{instance=~"$ClouddriverInstance",scope="global"}[$__interval])) by (basePhase)',
        legendFormat='{{basePhase}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Regional GCP Operations Started in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:operationWaitRequests{instance=~"$ClouddriverInstance",scope="regional",region=~"$GcpRegion"}[$__interval])) by (basePhase)',
        legendFormat='{{basePhase}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Zonal GCP Operations Started in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:operationWaitRequests{instance=~"$ClouddriverInstance",scope="zonal",zone=~".*$GcpRegion.*"}[$__interval])) by (basePhase)',
        legendFormat='{{basePhase}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Safe Retry Count',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Retryable Global GCP (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(label_replace(rate(clouddriver:google:safeRetry__count_total{instance=~"$ClouddriverInstance",scope="global"}[$__interval]), "operation", "$1", "operation", "compute.(.*)")) by (operation, phase)',
        legendFormat='{{phase}}.{{operation}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Safe Retry Latency',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Retryable Regional GCP in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(clouddriver:google:safeRetry__count_total{instance=~"$ClouddriverInstance",scope="regional",region=~"$GcpRegion"}[$__interval])) by (instance, phase, operation), "operation", "$1", "operation", "compute.(.*)")',
        legendFormat='{{phase}}.{{operation}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Retryable Zonal GCP in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(label_replace(sum(rate(clouddriver:google:safeRetry__count_total{instance=~"$ClouddriverInstance",scope="zonal",zone=~".*$GcpRegion.*"}[$__interval])) by (instance, phase, operation, cell), "operation", "$1", "operation", "compute.(.*)"), "cell", "$1", "zone", ".*-(.)")',
        legendFormat='{{phase}}.{{operation}}/{{cell}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Retryable Global GCP Latency (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(clouddriver:google:safeRetry__totalTime_total{instance=~"$ClouddriverInstance",scope="global"}[$__interval])) by (operation, phase) / sum(rate(clouddriver:google:safeRetry__count_total{instance=~"$ClouddriverInstance",scope="global"}[$__interval])) by (operation, phase), "operation", "$1", "operation", "compute.(.*)")',
        legendFormat='{{phase}}.{{operation}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Retryable Regional GCP Latency in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(clouddriver:google:safeRetry__totalTime_total{instance=~"$ClouddriverInstance",scope="regional",region=~"$GcpRegion"}[$__interval])) by (operation, phase) / sum(rate(clouddriver:google:safeRetry__count_total{instance=~"$ClouddriverInstance",scope="regional",region=~"$GcpRegion"}[$__interval])) by (operation, phase), "operation", "$1", "operation", "compute.(.*)")',
        legendFormat='{{phase}}.{{operation}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Retryable Zonal GCP Latency in $GcpRegion (clouddriver, $ClouddriverInstance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(label_replace(sum(rate(clouddriver:google:safeRetry__totalTime_total{instance=~"$ClouddriverInstance",scope="zonal",zone=~".*$GcpRegion.*"}[$__interval])) by (operation, phase, zone) / sum(rate(clouddriver:google:safeRetry__count_total{instance=~"$ClouddriverInstance",scope="zonal",zone=~".*$GcpRegion.*"}[$__interval])) by (operation, phase, zone), "cell", "$1", "zone", ".*-(.)")) by (phase, operation, cell), "operation", "$1", "operation", "compute.(.*)")',
        legendFormat='{{phase}}.{{operation}}/{{cell}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Google Storage',
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Google Storage Service Calls (front50, $Front50Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(front50:google:storage:invocation__count_total{instance=~"$Front50Instance"}[$__interval])) by (method)',
        legendFormat='{{method}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Google Storage Service Latency (front50, $Front50Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(front50:google:storage:invocation__totalTime_total{instance=~"$Front50Instance"}[$__interval])) by (method) / sum(rate(front50:google:storage:invocation__count_total{instance=~"$Front50Instance"}[$__interval])) by (method)',
        legendFormat='{{method}}',
      )
    )
  )
)
