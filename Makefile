# Prometheus Mixin Makefile
# Heavily copied from upstream project kubenetes-mixin
# How to use:
# With docker -> make
# Without docker (in CI) -> make SKIP_DOCKER=true

# Make defaults
# Use commonly available shell
SHELL := bash
# Fail if piped commands fail - critical for CI/etc
.SHELLFLAGS := -o errexit -o nounset -o pipefail -c
# Use one shell for a target, rather than shell per line
.ONESHELL:

JSONNET_CMD := jsonnet
JSONNET_FMT_CMD := jsonnetfmt
JB_CMD := jb

ifneq ($(SKIP_DOCKER),true)
	PROMETHEUS_DOCKER_IMAGE := prom/prometheus:latest
	# TODO: Find out why official prom images segfaults during `test rules` if not root
    PROMTOOL_CMD := docker pull ${PROMETHEUS_DOCKER_IMAGE} && \
		docker run \
			--user root \
			--volume $(PWD):/tmp \
			--workdir /tmp \
			--entrypoint promtool \
			$(PROMETHEUS_DOCKER_IMAGE)
else
	PROMTOOL_CMD := promtool
endif

all: fmt build test ## Format, build and test

clean: ## Clean up generated files
	rm -rf manifests/

fmt: ## Format Jsonnet
	find . -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- $(JSONNET_FMT_CMD) -i

dep: ## Install dependencies
	if [[ ! -d vendor/ ]]; then
		$(JB_CMD) install
	fi

build: dep ## Build dashboards and Prometheus files
	@mkdir -p manifests
	$(JSONNET_CMD) \
		-J vendor/ \
		-m manifests \
		lib/dashboards.jsonnet
	$(JSONNET_CMD) -S lib/alerts.jsonnet > manifests/prometheus_alerts.yaml
	$(JSONNET_CMD) -S lib/rules.jsonnet > manifests/prometheus_rules.yaml

test: ## Test generated files
	$(JSONNET_FMT_CMD) --version
	export failed=0
	export fs='$(shell find . -name '*.jsonnet' -o -name '*.libsonnet')'
	if [ $${#fs} -gt 0 ]; then
		for f in $${fs}; do
			if [ -e $${f} ]; then $(JSONNET_FMT_CMD) "$$f" | diff -u "$$f" - || export failed=1; fi
		done
	fi
	if [ "$$failed" -eq 1 ]; then
		exit 1
	fi

	$(PROMTOOL_CMD) check rules manifests/prometheus_rules.yaml
	$(PROMTOOL_CMD) check rules manifests/prometheus_alerts.yaml
	$(PROMTOOL_CMD) test rules tests.yaml

grafana: ## Start local Grafana and watch manifests for changes
	docker stop grafana || true
	docker run \
		--name grafana \
		--detach=true \
		--rm \
		--env GF_AUTH_ANONYMOUS_ENABLED="true" \
		--env GF_AUTH_ANONYMOUS_ORG_ROLE="Admin" \
		--env GF_AUTH_DISABLE_LOGIN_FORM="true" \
		--env GF_PATHS_PROVISIONING=/etc/grafana/conf/provisioning \
		--volume "$${PWD}/grafana-datasources.yaml:/etc/grafana/conf/provisioning/datasources/default.yaml" \
		--volume "$${PWD}/grafana-dashboards.yaml:/etc/grafana/conf/provisioning/dashboards/default.yaml" \
		--volume "$${PWD}/manifests/:/var/lib/grafana/dashboards" \
		--publish 3000:3000 \
		grafana/grafana
	@echo -e "\nPort Forward from Kubernetes with something like: \n
		kubectl port-forward --namespace prometheus svc/prometheus-k8s --address 0.0.0.0 9090 &"
	@echo -e "\nStop Grafana with:\n\ndocker stop grafana"


.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
