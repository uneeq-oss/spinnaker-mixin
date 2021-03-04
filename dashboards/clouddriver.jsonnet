local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Clouddriver',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='clouddriver',
)

// Links

.addLinks(
  [
    grafana.link.dashboards(
      icon='info',
      tags=[],
      title='GitHub',
      type='link',
      url='https://github.com/spinnaker/clouddriver',
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
    query='clouddriver',
    current='clouddriver',
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
.addTemplate(
  grafana.template.new(
    name='Account',
    datasource='$datasource',
    query='label_values(controller_invocations_total{job=~"$job"}, account)',
    allValues='.*',
    current='All',
    refresh=1,
    includeAll=true,
    sort=1,
  )
)
.addTemplate(
  grafana.template.custom(
    name='Platform',
    query='google,aws,kubernetes,docker,appengine,dcos',
    allValues='.*',
    current='All',
    includeAll=true,
  )
)

.addRow(
  grafana.row.new(
    title='Errors',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='$Account 5xx Errors (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_total{job=~"$job",instance=~"$Instance",status="5xx",account=~"$Account"}[$__interval])) by (controller, method, statusCode)',
        legendFormat='{{statusCode}}/{{controller}}/{{method}}'
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Validation Errors',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'validationErrors_total',
        legendFormat='{{operation}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Operations and Tasks',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='$Account Controller Invocation by Method (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_total{job=~"$job", instance=~"$Instance",account=~"$Account"}[$__interval])) by (controller, method)',
        legendFormat='{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Operation Failures by Operation (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_total{job=~"$job", instance=~"$Instance",account=~"$Account"}[$__interval])) by (controller, method)',
        legendFormat='{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='$Account Controller Invocation Latency by Method (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(operations_seconds_sum{success!="true"}[$__interval])) by (OperationType)\n/\nsum(rate(operations_seconds_count[$__interval])) by (OperationType)',
        legendFormat='{{OperationType}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(controller_invocations_seconds_sum{job=~"$job", instance=~"$Instance",account=~"$Account"}[$__interval])) by (controller, method) \n/\nsum(rate(controller_invocations_seconds_count{job=~"$job", instance=~"$Instance",account=~"$Account"}[$__interval])) by (controller, method)',
        legendFormat='{{controller}}/{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Tasks per Instance (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(tasks_total{job=~"$job", instance=~"$Instance"}[$__interval])) by (instance)',
        legendFormat='{{instance}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Operations by Operation (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(operations_seconds_count{job=~"$job", instance=~"$Instance"}[$__interval])) by (OperationType)',
        legendFormat='{{OperationType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Execution Count by Instance (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(executionCount_total{job=~"$job", instance=~"$Instance"}[$__interval])) by (instance)',
        legendFormat='{{instance}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Operation Time by Operation (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(operations_seconds_sum{job=~"$job",instance=~"$Instance"}[$__interval])) by (OperationType)\n/\nsum(rate(operations_seconds_count{job=~"$job",instance=~"$Instance"}[$__interval])) by (OperationType)',
        legendFormat='{{OperationType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Execution Latency by Instance (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(executionTime_seconds_sum{job=~"$job",instance=~"$Instance"}[$__interval])) by (instance)\n/\nsum(rate(executionTime_seconds_count{job=~"$job",instance=~"$Instance"}[$__interval])) by (instance)',
        legendFormat='{{instance}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='On Demand Reads by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(onDemand_read_seconds_count{job=~"$job",providerName=~".*$Platform.*", instance=~"$Instance"}[$__interval])) by (onDemandType)',
        legendFormat='{{onDemandType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Cache Agent Execution by Account (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (provider, account) (\n# provider\nlabel_replace(\n# account\nlabel_replace(\n# query\n(sum(rate(executionTime_seconds_count{job=~"$job", agent=~".*$Platform.*",instance=~"$Instance"}[$__interval])) by (agent)\n),\n"account", "$1", "agent", "^[A-Za-z]+/([A-Za-z0-9-]+).*"\n), \n"provider", "$1", "agent", "^([A-Za-z]+).*"\n)\n)',
        legendFormat='{{ provider }} :: {{ account }}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='On Demand Read Latency by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(onDemand_read_seconds_sum{job=~"$job",providerName=~".*$Platform.*", instance=~"$Instance"}[$__interval])) by (onDemandType)\n/\nsum(rate(onDemand_read_seconds_count{job=~"$job",providerName=~".*$Platform.*", instance=~"$Instance"}[$__interval])) by (onDemandType)',
        legendFormat='{{onDemandType}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='SQL Caching',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Cache Agent Execution Latency by Account (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (provider, account) (\n# provider\nlabel_replace(\n# account\nlabel_replace(\n# query\n(sum(rate(executionTime_seconds_sum{job=~"$job", agent=~".*$Platform.*",instance=~"$Instance"}[$__interval])) by (agent)\n),\n"account", "$1", "agent", "^[A-Za-z]+/([A-Za-z0-9-]+).*"\n), \n"provider", "$1", "agent", "^([A-Za-z]+).*"\n)\n)\n\n/\n\nsum by (provider, account) (\n# provider\nlabel_replace(\n# account\nlabel_replace(\n# query\n(sum(rate(executionTime_seconds_count{job=~"$job", agent=~".*$Platform.*",instance=~"$Instance"}[$__interval])) by (agent)\n),\n"account", "$1", "agent", "^[A-Za-z]+/([A-Za-z0-9-]+).*"\n), \n"provider", "$1", "agent", "^([A-Za-z]+).*"\n)\n)',
        legendFormat='{{ provider }} :: {{ account }}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(\nsum(rate(executionTime_seconds_sum{agent=~".*$Platform.*",instance=~"$Instance"}[$__interval])) by (agent)\n/\nsum(rate(executionTime_seconds_count{agent=~".*$Platform.*",instance=~"$Instance"}[$__interval])) by (agent), "itemType", "$1", "agent", "(?:.*(?:Amazon|Appengine|Google|Kubernetes|Dcos|/)([^/]*)CachingAgent.*)")',
        legendFormat='TBC',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Relationships Requested by Platform (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_sqlCache_get_relationshipsRequested_total{prefix=~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", ".*.clouddriver.([^\\\\.]*).*")',
        legendFormat='{{platform}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_sqlCache_get_relationshipsRequested_total{prefix!~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", "([^\\\\./]*).*")',
        legendFormat='{{platform}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Relationships Requested by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(cats_sqlCache_get_relationshipsRequested_total{prefix=~".*.$Platform.*", instance=~"$Instance"}[$__interval])) by (type)',
        legendFormat='{{type}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Requested by Platform (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_sqlCache_get_itemCount_total{prefix=~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", ".*.clouddriver.([^\\\\.]*).*")',
        legendFormat='{{platform}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_sqlCache_get_itemCount_total{prefix!~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", "([^\\\\./]*).*")',
        legendFormat='{{platform}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Requested by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(cats_sqlCache_get_itemCount_total{prefix=~".*.$Platform.*", instance=~"$Instance"}[$__interval])) by (type)',
        legendFormat='{{type}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Relationships Written by Platform (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_sqlCache_merge_relationshipCount_total{prefix=~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", ".*.clouddriver.([^\\\\.]*).*")',
        legendFormat='{{platform}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_sqlCache_merge_relationshipCount_total{prefix!~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", "([^\\\\./]*).*")',
        legendFormat='{{platform}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Relationships Written by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(cats_sqlCache_merge_relationshipCount_total{prefix=~".*.$Platform.*", instance=~"$Instance"}[$__interval])) by (type)',
        legendFormat='{{type}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Written by Platform (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_sqlCache_merge_itemCount_total{prefix=~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", ".*.clouddriver.([^\\\\.]*).*")',
        legendFormat='{{platform}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_sqlCache_merge_itemCount_total{prefix!~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", "([^\\\\./]*).*")',
        legendFormat='{{platform}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Written by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(cats_sqlCache_merge_itemCount_total{prefix=~".*.$Platform.*", instance=~"$Instance"}[$__interval])) by (type)',
        legendFormat='{{type}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Deleted by Platform (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_sqlCache_evict_itemCount_total{prefix=~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", ".*.clouddriver.([^\\\\.]*).*")',
        legendFormat='{{platform}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_sqlCache_evict_itemCount_total{prefix!~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", "([^\\\\./]*).*")',
        legendFormat='{{platform}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Deleted by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(cats_sqlCache_evict_itemCount_total{prefix=~".*.$Platform.*", instance=~"$Instance"}[$__interval])) by (type)',
        legendFormat='{{type}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Redis Caching',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Keys Requested by Platform (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_get_keysRequested_total{prefix=~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", ".*.clouddriver.([^\\\\.]*).*")',
        legendFormat='{{platform}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_get_keysRequested_total{prefix!~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", "([^\\\\./]*).*")',
        legendFormat='{{platform}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Keys Requested by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(cats_redisCache_get_keysRequested_total{prefix=~".*.$Platform.*", instance=~"$Instance"}[$__interval])) by (type)',
        legendFormat='{{type}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Requested by Platform (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_get_itemCount_total{prefix=~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", ".*.clouddriver.([^\\\\.]*).*")',
        legendFormat='{{platform}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_get_itemCount_total{prefix!~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", "([^\\\\./]*).*")',
        legendFormat='{{platform}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Requested by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(cats_redisCache_get_itemCount_total{prefix=~".*.$Platform.*", instance=~"$Instance"}[$__interval])) by (type)',
        legendFormat='{{type}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Keys Written by Platform (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_merge_keysWritten_total{prefix=~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", ".*.clouddriver.([^\\\\.]*).*")',
        legendFormat='{{platform}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_merge_keysWritten_total{prefix!~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", "([^\\\\./]*).*")',
        legendFormat='{{platform}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Keys Written by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(cats_redisCache_merge_keysWritten_total{prefix=~".*.$Platform.*", instance=~"$Instance"}[$__interval])) by (type)',
        legendFormat='{{type}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Written by Platform (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_merge_itemCount_total{prefix=~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", ".*.clouddriver.([^\\\\.]*).*")',
        legendFormat='{{platform}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_merge_itemCount_total{prefix!~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", "([^\\\\./]*).*")',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Written by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(cats_redisCache_merge_itemCount_total{prefix=~".*.$Platform.*", instance=~"$Instance"}[$__interval])) by (type)',
        legendFormat='{{type}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_evict_itemCount_total{prefix=~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", ".*.clouddriver.([^\\\\.]*).*")',
        legendFormat='{{platform}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Keys Deleted by Platform (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_evict_itemCount_total{prefix!~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", "([^\\\\./]*).*")',
        legendFormat='{{platform}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Keys Deleted by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(cats_redisCache_evict_keysDeleted_total{prefix=~".*.$Platform.*", instance=~"$Instance"}[$__interval])) by (type)',
        legendFormat='{{type}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Deleted by Platform (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_evict_itemCount_total{prefix=~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", ".*.clouddriver.([^\\\\.]*).*")',
        legendFormat='{{platform}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(cats_redisCache_evict_itemCount_total{prefix!~"com.netflix.*", instance=~"$Instance"}[$__interval])) by (prefix), "platform", "$1", "prefix", "([^\\\\./]*).*")',
        legendFormat='{{platform}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='CATS Items Deleted by Type (clouddriver, $Instance, $Platform)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(cats_redisCache_evict_itemCount_total{prefix=~".*.$Platform.*", instance=~"$Instance"}[$__interval])) by (type)',
        legendFormat='{{type}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='TODO - Google Operations - Confirm metric names',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Google Operation Failures (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Google Operation Wait Until Done Time (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:operationWaits__count_total{instance=~"$Instance",status!="DONE"}[$__interval])) by (basePhase, scope) ',
        legendFormat='{{scope}}/{{basePhase}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:operationWaits__totalTime_total{instance=~"$Instance"}[$__interval])) by (basePhase, scope) / sum(rate(clouddriver:google:operationWaits__count_total{instance=~"$Instance"}[$__interval])) by (basePhase, scope) ',
        legendFormat='{{scope}}/{{basePhase}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum((clouddriver:google:operationWaits__totalTime_total{instance=~"$Instance"})) by (basePhase, scope) / sum((clouddriver:google:operationWaits__count_total{instance=~"$Instance"})) by (basePhase, scope) ',
        legendFormat='{{scope}}/{{basePhase}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'clouddriver:google:operationWaits__count_total{instance=~"$Instance"}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'clouddriver:google:operationWaitRequests',
        legendFormat='{{scope}}/{{basePhase}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Google Operations Started (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Google Operation Success (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(clouddriver:google:operationWaits__count_total{instance=~"$Instance",status="DONE"}[$__interval])) by (basePhase)',
        legendFormat='{{basePhase}}',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Amazon Operations',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Amazon Client Rate Limiting by ClientType (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'avg(rate(amazonClientProvider_rateLimitDelayMil[$__interval])) by (clientType)',
        legendFormat='{{clientType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='$Account Cache Drift by Region/Agent (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(\n# query\navg(cache_drift{account=~"$Account", instance=~"$Instance"}) by (account, agent, region),\n"agent", "$1", "agent",  "(.*)CachingAgent"\n)',
        legendFormat='{{account}}/{{region}}/{{agent}}',
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
