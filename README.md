# Prometheus Metrics

The Spinnaker services can expose Prometheus metrics on
`*:<service_port>/aop-prometheus` when using the [Armory Observability
Plugin](https://github.com/armory-plugins/armory-observability-plugin).

These metrics enable operators to observe how it is performing. For example 
how many pipelines have been triggered, any errors with cloud providers or REST
calls between services. 

These metrics can be scraped by a Prometheus server and viewed in Prometheus,
displayed on a Grafana dashboard and/or trigger alerts to Slack/etc.

## Prometheus Mixin

A Prometheus mixin bundles all of the metric related concerns into a single
package for users of the application to consume.
Typically this includes dashboards, recording rules, alerts and alert logic
tests.

By creating a mixin, application maintainers and contributors to the project
can enshrine knowledge about operating the application and potential SLO's
that users may wish to use. 

For more details about this concept see the [monitoring-mixins](https://github.com/monitoring-mixins/docs)
project on GitHub.

## Scraping the metrics manually

Assuming Spinnaker has been installed into Kubernetes and the plugin has been
installed you can access the metrics via Kubernetes port-forward to your pod:

```
$ kubectl port-forward orca-6786f98464-ckml8 8083 &
[1] 293283
```

Then query the metrics endpoint:
```
$ curl localhost:7002/metrics

<snip>
# TYPE stage_invocations_total counter
stage_invocations_total{application="myapp1",cloudProvider="kubernetes",hostname="orca-6786f98464-ckml8",lib="aop",libVer="v1.0.0",spinSvc="orca",type="deployManifest",version="1.0.0",} 3.0
stage_invocations_total{application="myapp2",cloudProvider="kubernetes",hostname="orca-6786f98464-ckml8",lib="aop",libVer="v1.0.0",spinSvc="orca",type="deployManifest",version="1.0.0",} 16.0
stage_invocations_total{application="myapp3",cloudProvider="kubernetes",hostname="orca-6786f98464-ckml8",lib="aop",libVer="v1.0.0",spinSvc="orca",type="deployManifest",version="1.0.0",} 4.0
# HELP stage_invocations_duration_seconds_max
# TYPE stage_invocations_duration_seconds_max gauge
stage_invocations_duration_seconds_max{cloudProvider="kubernetes",hostname="orca-6786f98464-ckml8",lib="aop",libVer="v1.0.0",spinSvc="orca",stageType="deployManifest",status="SUCCEEDED",version="1.0.0",} 0.0
```

## Scraping metrics with the Prometheus Operator

The [Prometheus Operator](https://github.com/coreos/prometheus-operator)
supports a couple of Kubernetes native scrape target `CustomResourceDefinitions`.

This project includes a [PodMonitor](podmonitor.yaml) CRD definition that is
defaults to scraping all `Pods` with annoation `prometheus.io/scrape= "true"` on 
port `8008`. 

The scrape port is different from the default because if we apply [Principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege) then Prometheus doesn't need and shouldn't 
have access to the Spinnaker API's.

If you would like to scrape each services default port then you can use the
included `PodMonitor` as a base and duplicate per application, modifying the 
the selectors pod labels and target port number each time.

Submit the `PodMonitor` CustomResourceDefinition to Kubernetes API:
```
$ kubectl apply -f podmonitor.yaml
```

The Prometheus Operator will trigger a reload of Prometheus configuration and
you should see the Sealed Secrets Controller in your Prometheus UI under 
`Service Discovery` and `Targets`.

## Grafana dashboard

The [dashboards](./dashboards/) can be imported standalone into Grafana. 
You may need to edit the datasource if you have configured your Prometheus 
datasource with a different name.

## Using the mixin with kube-prometheus

See the [kube-prometheus](https://github.com/coreos/kube-prometheus#kube-prometheus)
project documentation for instructions on importing mixins.

## Using the mixin as raw YAML files

If you don't use the jsonnet based `kube-prometheus` project then you will need to
generate the raw yaml files for inclusion in your Prometheus installation.

Install the `jsonnet` dependencies:
```
$ go get github.com/google/go-jsonnet/cmd/jsonnet
$ go get github.com/google/go-jsonnet/cmd/jsonnetfmt
```

Generate yaml:
```
$ make
```

## Contributing

Pull requests are most welcome.

Please see the
[monitoring-mixins guidelines for alert names](https://github.com/monitoring-mixins/docs#guidelines-for-alert-names-labels-and-annotations) for conventions we attempt to follow.

New alerts should generally be accompanied by a relevant unit test in
[tests.yaml](./tests.yaml). Tests help readers understand the alerts purpose and
also catch edge cases.
