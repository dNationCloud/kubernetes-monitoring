# Dashboards and Alerts only Installation

Installation on top of an existing monitoring infrastructure (Prometheus Operator, Grafana and Loki are already installed).

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

Search for `Kubernetes Monitoring` dashboard. The fun starts here :).  
If you want to set the `Kubernetes Monitoring` dashboard as a home dashboard follow [here](https://grafana.com/docs/grafana/latest/administration/change-home-dashboard/#set-the-default-dashboard-through-preferences).
If you're experiencing issues please read [FAQ](helpers/FAQ.md).

## Configuration

TODO
