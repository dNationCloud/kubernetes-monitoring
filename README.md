# <img src="images/logo.png" width="60" height="auto"> Kubernetes Monitoring (K8s-m8g)  

A set of Grafana dashboards and Prometheus alerts to cover Kubernetes monitoring in an easy way using a drill-down principle.

# Getting Started

K8s-m8g helm chart is designed to be installed on top of the existing [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
and [loki-stack](https://github.com/grafana/loki/tree/master/production/helm/loki-stack) monitoring infrastructure.

### Prerequisites

* [Helm3](https://helm.sh/)

### Installation

K8s-m8g helm chart is currently hosted in the public [ifne](https://www.ifne.eu/) helm repository.

```bash
# Add ifne helm repository
helm repo add ifne https://nexus.ifne.eu/repository/ifne-helm-public/
helm repo update

# Install K8s-m8g
kubectl create namespace monitoring
helm install k8s-m8g ifne/k8s-m8g --namespace monitoring
```

Keep in mind that K8s-m8g helm chart is designed to be installed on the top of the existing Prometheus, Prometheus Alertmanager, Loki and Grafana deployments.

# Contribution guidelines

If you want to contribute to the K8s-m8g project, be sure to review the
[contribution guidelines](CONTRIBUTING.md). This project adheres to K8s-m8g's
[code of conduct](CODE_OF_CONDUCT.md). When participating, you are required to abide by the code of conduct.

We use GitHub issues to manage requests and bugs, please visit our discussion forum if you have any questions.

# Build 

Grafana dashboards and Prometheus alerts are stored in the [jsonnet](https://jsonnet.org/) templates. 

### Prerequisites

- [Docker](https://www.docker.com/)

### Build Jsonnet templates

```
mkdir templates/k8s-m8g
docker run -u `id -u` --rm -t -v `pwd`:/src dnationcloud/jsonnet:latest jsonnet -m templates/k8s-m8g -S jsonnet/helm.jsonnet
```

### Jsonnet Formatter & Linter

```
find ./jsonnet/ -type f -regex '.*\.\(libsonnet\|jsonnet\)' -print |  while read f; do docker run -u `id -u` --rm -t -v `pwd`:/src dnationcloud/jsonnet:latest jsonnetfmt -i "$f" || exit 1; done;
find ./jsonnet/ -type f -regex '.*\.\(libsonnet\|jsonnet\)' -print |  while read f; do docker run -u `id -u` --rm -t -v `pwd`:/src dnationcloud/jsonnet:latest jsonnet-lint "$f" || exit 1; done;
```

# License

[Apache License 2.0](LICENSE)

# Project Background

K8s-m8g project is developed, maintained and used in production by [dNation](https://www.dnation.tech/) professionals 
to simplify their day-to-day monitoring tasks.  
The development of K8s-m8g was transformed to an open source project in October 2020.
