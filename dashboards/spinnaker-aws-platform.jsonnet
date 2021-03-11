local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Spinnaker AWS Platform',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='spinnaker-aws-platform',
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
    name='AwsRegion',
    datasource='$datasource',
    query='aws_request_httpRequestTime_seconds_count',
    allValues='.*',
    current='All',
    regex='/.*serviceEndpoint="[^\\.]+\\.([^\\.]+).*/',
    refresh=2,
    includeAll=true,
    sort=1,
  )
)
.addTemplate(
  grafana.template.new(
    name='Instance',
    datasource='$datasource',
    query='label_values(aws_request_httpRequestTime_seconds_count, instance)',
    allValues='.*',
    current='All',
    refresh=2,
    includeAll=true,
    sort=1,
  )
)

.addRow(
  grafana.row.new(
    title='AWS',
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS Delay by Service  (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(AWS_delay_sum{instance=~"$Instance", statusCode="-1"}) by (serviceName)\n/\nsum(AWS_delay_count{instance=~"$Instance", statusCode="-1"}) by (serviceName) , "serviceName", "$1", "serviceName", "Amazon(.+)")',
        legendFormat='{{serviceName}} / UNK',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(AWS_delay_sum{instance=~"$Instance", statusCode!="-1"}) by (serviceName, statusCode)\n/\nsum(AWS_delay_count{instance=~"$Instance", statusCode!="-1"}) by (serviceName, statusCode), "serviceName", "$1", "serviceName", "Amazon(.+)") ',
        legendFormat='{{serviceName}} / {{statusCode}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS Delay by Request (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(AWS_delay_sum{instance=~"$Instance", statusCode="-1"}) by (requestType)\n/\nsum(AWS_delay_count{instance=~"$Instance", statusCode="-1"}) by (requestType) ',
        legendFormat='{{requestType}} / UNK',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(AWS_delay_sum{instance=~"$Instance", statusCode!="-1"}) by (requestType, statusCode)\n/\nsum(AWS_delay_count{instance=~"$Instance", statusCode!="-1"}) by (requestType, statusCode) ',
        legendFormat='{{requestType}} / {{statusCode}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS Errors by Region (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(aws_request_httpRequestTime_seconds_count{instance=~"$Instance",serviceEndpoint=~".*$AwsRegion.*",error="true"}[$__interval])) by (serviceEndpoint, statusCode), "region", "$1", "serviceEndpoint", "[^\\\\.]+\\\\.([^\\\\.]+).*")',
        legendFormat='{{region}} / {{statusCode}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS Errors in $AwsRegion (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(label_replace(sum(rate(aws_request_httpRequestTime_seconds_count{instance=~"$Instance",serviceEndpoint=~".*$AwsRegion.*",error="true"}[$__interval])) by (requestType, serviceName, statusCode, AWSErrorCode), "requestType", "$1", "requestType", "(.*)Request(.*)"), "serviceName",  "$1", "serviceName", "Amazon(.+)")',
        legendFormat='{{statusCode}}/{{serviceName}}.{{requestType}}->{{AWSErrorCode}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS EC2 Requests  by Region (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(aws_request_httpRequestTime_seconds_count{instance=~"$Instance",serviceName="AmazonEC2", error="false"}[$__interval])) by (serviceEndpoint), "region", "$1", "serviceEndpoint", "[^\\\\.]+\\\\.([^\\\\.]+).*")',
        legendFormat='{{region}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS EC2 Requests in $AwsRegion (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(aws_request_httpRequestTime_seconds_count{instance=~"$Instance",serviceEndpoint=~".*$AwsRegion.*",serviceName="AmazonEC2", error="false"}[$__interval])) by (requestType, serviceName), "requestType", "$1", "requestType", "(.*)Request")',
        legendFormat='{{requestType}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS EC2 Request Latency by Region  (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(aws_request_httpRequestTime_seconds_sum{instance=~"$Instance",serviceEndpoint=~".*$AwsRegion.*",serviceName="AmazonEC2"}[$__interval])) by (serviceEndpoint, serviceName)\n/ sum(rate(aws_request_httpRequestTime_seconds_count{instance=~"$Instance",serviceName="AmazonEC2", error="false"}[$__interval])) by (serviceEndpoint, serviceName), "region", "$1", "serviceEndpoint", "[^\\\\.]+\\\\.([^\\\\.]+).*")',
        legendFormat='{{region}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS EC2 Request Latency in $AwsRegion  (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(aws_request_httpRequestTime_seconds_sum{instance=~"$Instance",serviceEndpoint=~".*$AwsRegion.*",serviceName="AmazonEC2"}[$__interval])) by (requestType, serviceName)\n/ sum(rate(aws_request_httpRequestTime_seconds_count{instance=~"$Instance",serviceName="AmazonEC2", error="false"}[$__interval])) by (requestType, serviceName)',
        legendFormat='{{requestType}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS Requests (non EC2) by Region (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(aws_request_httpRequestTime_seconds_count{instance=~"$Instance",serviceEndpoint=~".*$AwsRegion.*",serviceName!="AmazonEC2", error="false"}[$__interval])) by (serviceName, serviceEndpoint), "region", "$1", "serviceEndpoint", "[^\\\\.]+\\\\.([^\\\\.]+).*")',
        legendFormat='{{serviceName}} / {{region}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS Requests (non EC2) in $AwsRegion (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(sum(rate(aws_request_httpRequestTime_seconds_count{instance=~"$Instance",serviceEndpoint=~".*$AwsRegion.*",serviceName!="AmazonEC2", error="false"}[$__interval])) by (requestType, serviceName), "serviceName", "$1", "serviceName", "Amazon(.+)")',
        legendFormat='{{serviceName}}.{{requestType}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS Non-EC2 Request Latency by Region  (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(label_replace(sum(rate(aws_request_httpRequestTime_seconds_sum{instance=~"$Instance",serviceEndpoint=~".*$AwsRegion.*",serviceName!="AmazonEC2"}[$__interval])) by (serviceEndpoint, serviceName)\n/ sum(rate(aws_request_httpRequestTime_seconds_count{serviceName!="AmazonEC2", error="false"}[$__interval])) by (serviceEndpoint, serviceName), "serviceName", "$1", "serviceName", "Amazon(.+)"), "region", "$1", "serviceEndpoint", "[^\\\\.]+\\\\.([^\\\\.]+).*")',
        legendFormat='{{serviceName}} / {{region}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='AWS Non-EC2 Request Latency in $AwsRegion  (clouddriver, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'label_replace(label_replace(sum(rate(aws_request_httpRequestTime_seconds_sum{instance=~"$Instance",serviceEndpoint=~".*$AwsRegion.*",serviceName!="AmazonEC2"}[$__interval])) by (requestType, serviceName)\n/\nsum(rate(aws_request_httpRequestTime_seconds_count{serviceName!="AmazonEC2", error="false"}[$__interval])) by (requestType, serviceName), "serviceName", "$1", "serviceName", "Amazon(.+)"), "requestType", "$1", "requestType", "(.*)Request")',
        legendFormat='{{serviceName}}.{{requestType}}',
      )
    )
  )
)
