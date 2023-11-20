# Helpers

A set of scripts and configuration files which helps to simplify local development.

## Local development using KinD (Kubernetes in Docker)

Prerequisites

* [Kind](https://kind.sigs.k8s.io/)
* [Docker](https://www.docker.com/)
* [Helm3](https://helm.sh/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

Grafana dashboards and Prometheus alerts are stored in the [jsonnet](https://jsonnet.org/) templates.

Jsonnet templates are shipped in compressed form by the k8s configmap.
Then the k8s configmap with compressed jsonnet is consumed by [kubernetes-jsonnet-translator](https://github.com/dNationCloud/kubernetes-jsonnet-translator).
[kubernetes-jsonnet-translator](https://github.com/dNationCloud/kubernetes-jsonnet-translator) translates jsonnet templates to the plain json and generates prometheus rule or grafana configmap k8s objects.

If you want to test your local changes in local KinD k8s cluster use following steps:

1. Create KinD cluster
```bash
kind create cluster --config helpers/kind_cluster_config.yaml --image kindest/node:v1.25.11
```
1. Install kubernetes-monitoring-stack (without dNation Kubernetes Monitoring dependency)
K8s-m8g-stack is an umbrella helm chart which deploys Grafana, Loki and Prometheus Operator projects.
```bash
# Add dNation helm repository
helm repo add dnationcloud https://dnationcloud.github.io/helm-hub/
helm repo update

# Install dNation Kubernetes Monitoring Stack without dNation Kubernetes Monitoring chart
helm install dnation-kubernetes-monitoring-stack dnationcloud/dnation-kubernetes-monitoring-stack -f https://raw.githubusercontent.com/dNationCloud/kubernetes-monitoring-stack/main/helpers/values-kind.yaml --set dnation-kubernetes-monitoring.enabled=false
```

1. Follow installation notes and use Port Forwarding if you want to access the Grafana server from outside your KinD cluster
```bash
export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=dnation-kubernetes-monitoring-stack" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace default port-forward $POD_NAME 3000
```

1. Package jsonnet templates
```bash
make jsonnet-package
```
1. Deploy dNation Kubernetes Monitoring with your changes
```bash
# Update K8s monitoring chart dependencies
helm dependency update chart
# K8s monitoring only (default)
helm install dnation-kubernetes-monitoring chart --set releaseOverride=dnation-kubernetes-monitoring-stack
# Cluster monitoring example with custom dashboard templates
helm install dnation-kubernetes-monitoring chart --set releaseOverride=dnation-kubernetes-monitoring-stack -f helpers/values-cluster-elk.yaml
# Host monitoring example
helm install dnation-kubernetes-monitoring chart --set releaseOverride=dnation-kubernetes-monitoring-stack -f helpers/values-host.yaml
# Multi-cluster monitoring example
helm install dnation-kubernetes-monitoring chart --set releaseOverride=dnation-kubernetes-monitoring-stack -f helpers/values-multicluster.yaml
```

If you want to run jsonnet formatter or linter use following:
```bash
# Format jsonnet files
make jsonnet-fmt
# Lint jsonnet files
make jsonnet-lint
```
If you want to generate plain json grafana dashboards or prometheus rules use following:
```bash
# Build json grafana dashboards
make json-dashboards
# Build json prometheus rules
make json-rules
```
If you want to run helm linter use following:
```bash
# Lint helm chart
make helm-lint
```
