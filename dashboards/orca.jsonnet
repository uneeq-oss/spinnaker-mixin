local hrm = import './http-request-metrics.jsonnet';
local jvm = import './jvm-metrics.jsonnet';
local kpm = import './kubernetes-pod-metrics.jsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Orca',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='spinnaker-orca',
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
  grafana.row.new(
    title='Key Metrics',
  )
  .addPanel(
    grafana.text.new(
      title='Service Description',
      content='Orca is the orchestration engine for Spinnaker. It is responsible for taking an execution definition and managing the stages and tasks, coordinating the other Spinnaker services.',
      span=3,
    ) + {
      // Grafonnet 6.0 `text.new()` doesn't support `.addLink(...)`
      links: [{
        title: 'Medium Blog Post: Monitoring Spinnaker Part 1',
        url: 'https://blog.spinnaker.io/monitoring-spinnaker-part-1-4847f42a3abd',
      }],
    }
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Active Executions',
      description='The primary domain model is an Execution, of which there are two types: PIPELINE and ORCHESTRATION. \n\nThe PIPELINE type is, you guessed it, for pipelines while ORCHESTRATION is what you see in the “Tasks” tab for an application. \n\nThis is really just good insight for answering the question of workload distribution. \n\nSince adding this metric, we’ve never seen it crater, but if that were to happen it’d be bad. \n\nFor Netflix, most ORCHESTRATION executions are API clients. \n\nDisregarding what the execution is doing, there’s no baseline cost difference between a running orchestration and a pipeline.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'max by (executionType) (\n  executions_active{container="orca"}\n)',
        legendFormat='{{ executionType }}'
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocation Time',
      description='If you’ve got a lot of 500’s, check your logs. \n\nWhen we see a spike in either invocation times or 5xx errors, it’s usually one of two things: \n\n1) Clouddriver is having a bad day, \n\n2) Orca doesn’t have enough capacity in some respect to service people polling for pipeline status updates. \n\nYou’ll need to dig elsewhere to find the cause.',
      datasource='$datasource',
      span=3,
      format='dtdurations',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (controller, status) (\n  rate(controller_invocations_seconds_sum{container="orca"}[$__rate_interval])\n) \n/\nsum by (controller, status) (\n  rate(controller_invocations_seconds_count{container="orca"}[$__rate_interval])\n)\n',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Rate of Task Invocations',
      description='This will look similar to the first metric we looked at, but this is directly looking at our queue: \n\nThis is the number of Execution-related Messages that we’re invoking every second.\n\nIf this drops, it’s a sign that your QueueProcessor may be starting to freeze up.\n\nAt that point, check that the thread pool it’s on isn’t starved for threads.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (executionType) (\n  rate(task_invocations_duration_seconds_count{container="orca"}[$__rate_interval])\n)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Task Invocations by Application',
      description='This is handy to see who your biggest customers are, from a pure orchestration volume perspective. \n\nOften times, if we start to experience pain and see a large uptick in queue usage, it’ll be due to a large submission from one or two customers. \n\nIf we were having pain, we could bump our capacity, or look to adjust some rate limits.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (application, executionType) (\n  rate(\n    task_invocations_duration_seconds_count{container="orca", status="RUNNING"}[$__rate_interval])\n) ',
        legendFormat='{{ application }} - {{ executionType }}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Message Handler Executor Usage',
      datasource='$datasource',
      description='This is our thread pool for the Message Handlers.\n\n\nSpare capacity is good.\n\nActive is actual active usage.\n\nBlocking is when a thread is blocked. \n\nBlockingQueueSize is bad, especially "pollSkippedNoCapacity" should always block blockingQueueSize being changed from 0.',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  threadpool_activeCount{container="orca"}\n)',
        legendFormat='Active',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  threadpool_blockingQueueSize{container="orca"}\n)',
        legendFormat='Blocking',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  threadpool_poolSize{container="orca"}\n)',
        legendFormat='Size',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Rate of Queue Messages Pushed / Acked (s)',
      description='If messages pushed is out pacing acked, you’re presently having a bad time. \n\nMost messages will complete in a blink of an eye, only RunTask will really take much time. \n\nIf you see an uptick in messages pushed, but not a correlating ack’d, it’s a good indicator you’ve got a downstream service issue that’s preventing message handlers completing: \n\nTake a look at Clouddriver, it probably wants your love and attention.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  rate(queue_pushed_messages_total{container="orca"}[$__rate_interval])\n)',
        legendFormat='Pushed',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  rate(queue_acknowledged_messages_total{container="orca"}[$__rate_interval])\n)',
        legendFormat="Ack'd",
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Queue Depth',
      description='Keiko supports setting a delivery time for messages, so you’ll always see queued messages outpacing in-process messages if your Spinnaker install is active.\n\nThings like wait tasks, execution windows, retries, and so-on all schedule message delivery in the future, and in-process messages are usually in-process for a handful of milliseconds.\n\nOperating Orca, one of your life mission is to keep ready messages at 0. \n\nA ready message is a message that has a delivery time of now or in the past, but it hasn’t been picked up and transitioned into processing yet: \n\nThis is a key contributor to a complaint of, “Spinnaker is slow.” \n\nAs I’ve mentioned before, Orca is horizontally scalable. \n\nGive Orca an adrenaline shot of instances if you see ready messages over 0 for more than two intervals so you can clear the queue out.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  queue_depth{container="orca"}\n)',
        legendFormat='queued',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  queue_ready_depth{container="orca"}\n)',
        legendFormat='ready',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\nqueue_unacked_depth{container="orca"}\n)',
        legendFormat='unacked',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Queue Errors',
      datasource='$datasource',
      description='Retried is a normal error condition by itself. \n\nDead-lettered occurs when a message has been retried a bunch of times and has never been successfully delivered.\n\nOrphaned messages are bad. \n\nThey’re messages whose message contents are in the queue, but do not have a pointer in either the queue set or unacked set. \n\nThis is a sign of an internal error, likely a troubling issue with Redis. \n\nIt “should never happen” if your system is healthy, and likewise “should never happen” even if your system is really, really overloaded. It’s worth a bug report.',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  queue_retried_messages_total{container="orca"}\n)',
        legendFormat='retried',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  rate(queue_orphaned_messages{container="orca"}[$__rate_interval])\n)',
        legendFormat='orphaned',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Message Lag',
      description='This is a measurement of a message’s desired delivery time and the actual delivery time: Smaller and tighter is better. This is a timer measurement of every message’s (usually very short) life in a ready state. When your queue gets backed up, this number will grow. \n\nWe consider this one of Orca’s key performance indicators.\n\nA mean message lag of anything under a few hundred milliseconds is fine. \n\nDon’t panic until you’re getting around a second. \n\nScale up, everything should be fine.',
      datasource='$datasource',
      span=3,
      format='dtdurations',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  queue_message_lag_seconds_sum\n)\n/\nsum(\n  queue_message_lag_seconds_count\n)',
        legendFormat='mean',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'max(queue_message_lag_seconds_max)',
        legendFormat='max',
      )
    )
  )
)

.addRow(
  grafana.row.new(
    title='Additional Metrics',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Active Stages per Type/Platform (orca, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_total{job=~"$job", instance=~"$Instance"}[$__rate_interval])) by (cloudProvider, type)',
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
        'sum(rate(stage_invocations_duration_total{job=~"$job", instance=~"$Instance"}[$__rate_interval])) by (cloudProvider, stageType)',
        legendFormat='{{stageType}}/{{cloudProvider}}',
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
        'sum(rate(stage_invocations_duration_total{job=~"$job", instance=~"$Instance", bucket!="lt5m"}[$__rate_interval])) by (stageType, cloudProvider, bucket)',
        legendFormat='{{bucket}}/{{cloudProvider}}/{{stageType}}',
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
        'sum(rate(threadpool_blockingQueueSize{job=~"$job", instance=~"$Instance"}[$__rate_interval])) by (id)',
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
        'sum(rate(queue_retried_messages_total{job=~"$job", instance=~"$Instance"}[$__rate_interval])) by (job)',
        legendFormat='Retried',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(queue_dead_messages_total{job=~"$job", instance=~"$Instance"}[$__rate_interval])) by (job)',
        legendFormat='Dead',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(queue_orphaned_messages{job=~"$job", instance=~"$Instance"}[$__rate_interval])) by (job)',
        legendFormat='Orphaned',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Message Lag Time (orca, $Instance)',
      datasource='$datasource',
      span=3,
      format='dtdurations',
    )
    .addTarget(
      grafana.prometheus.target(
        'rate(queue_message_lag_seconds_count{job=~"$job", instance=~"$Instance"}[$__rate_interval])',
        legendFormat='messages {{ instance }}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'rate(queue_message_lag_seconds_sum{job=~"$job", instance=~"$Instance"}[$__rate_interval])\n/\nrate(queue_message_lag_seconds_count{job=~"$job", instance=~"$Instance"}[$__rate_interval])',
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
        'sum(rate(queue_pushed_messages_total{job=~"$job", instance=~"$Instance"}[$__rate_interval])) by (instance)',
        legendFormat='Pushed/{{ instance }}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(queue_acknowledged_messages_total{instance=~"$Instance"}[$__rate_interval])) by (instance)',
        legendFormat='Acknowledged/{{ instance }}',
      )
    )
  )
)

.addRow(hrm)

.addRow(jvm)

.addRow(kpm)
