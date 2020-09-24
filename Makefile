# Prometheus Mixin Makefile
# Heavily copied from upstream project kubenetes-mixin
# How to use:
# With docker -> make
# Without docker (in CI) -> make SKIP_DOCKER=true

JSONNET_FMT := jsonnetfmt -n 2 --max-blank-lines 2 --string-style s --comment-style s

ifneq ($(SKIP_DOCKER),true)
	DOCKER_IMAGE := registry.gitlab.com/faceme-projects/infrastructure/prometheus-builder:latest
    PROMTOOL_CMD := docker pull ${DOCKER_IMAGE} && \
		docker run \
			-v $(PWD):/tmp \
			--entrypoint promtool \
			$(DOCKER_IMAGE)
	## Based on -v mount above
	WORKING_DIR := /tmp
else
	PROMTOOL_CMD := promtool
	## Based on current location where this Makefile is
	WORKING_DIR := .
endif

all: fmt prometheus_alerts.yaml prometheus_rules.yaml dashboards_out lint test ## Generate files, lint and test

fmt: ## Format Jsonnet
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- $(JSONNET_FMT) -i

prometheus_alerts.yaml: mixin.libsonnet lib/alerts.jsonnet alerts/*.libsonnet ## Generate Alerts YAML
	@mkdir -p manifests
	jsonnet -S lib/alerts.jsonnet > manifests/$@

prometheus_rules.yaml: mixin.libsonnet lib/rules.jsonnet rules/*.libsonnet ## Generate Rules YAML
	@mkdir -p manifests
	jsonnet -S lib/rules.jsonnet > manifests/$@

dashboards_out: mixin.libsonnet lib/dashboards.jsonnet dashboards/*.libsonnet ## Generate Dashboards JSON
	jsonnet -J vendor -m manifests lib/dashboards.jsonnet

lint: prometheus_alerts.yaml prometheus_rules.yaml ## Lint and check YAML
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		while read f; do \
			$(JSONNET_FMT) "$$f" | diff -u "$$f" -; \
		done
	$(PROMTOOL_CMD) check rules $(WORKING_DIR)/manifests/prometheus_rules.yaml
	$(PROMTOOL_CMD) check rules $(WORKING_DIR)/manifests/prometheus_alerts.yaml

clean: ## Clean up generated files
	rm -rf manifests/

test: prometheus_alerts.yaml prometheus_rules.yaml ## Test generated files
	$(PROMTOOL_CMD) test rules $(WORKING_DIR)/tests.yaml

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

