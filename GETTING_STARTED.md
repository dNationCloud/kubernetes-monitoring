# Dashboards and Alerts only Installation

Installation on top of an existing monitoring infrastructure (Prometheus, Grafana and Loki are already installed).

## Installation

Prerequisites
* [Helm3](https://helm.sh/)

dNation Kubernetes Monitoring helm chart is hosted in the [dNation helm repository](https://artifacthub.io/packages/search?repo=dnationcloud).
```bash
# Add dNation helm repository
helm repo add dnationcloud https://dnationcloud.github.io/helm-hub/
helm repo update

# Install dNation Kubernetes Monitoring
helm install dnation-kubernetes-monitoring dnationcloud/dnation-kubernetes-monitoring
```

## Configuration

| Parameter | Description | Default | 
|-----|------|---------|
| dashboardLabel.name | Label name for grafana dashboard resources | `"grafana_dashboard"` |
| dashboardLabel.value | Label value for grafana dashboard resources  | `"1"` |
| ruleLabel.name | Label name for prometheus rule resources | `"prometheus_rule"` |
| ruleLabel.value | Label value for prometheus rule resources | `"1"` |
| fullnameOverride | Override a full name of resources | `""` |
| nameOverride | Override value of `app` label used by k8s objects | `""` |
| namespaceOverride | Override the deployment namespace | `""` |
