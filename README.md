<a href="https://dnation.tech/"><img width="250" alt="dNationCloud" src="https://storage.googleapis.com/ifne.eu/public/icons/dnation.png"></a>

# <img src="https://storage.googleapis.com/ifne.eu/public/icons/dnation_k8sm8g.png" width="60" height="auto"> Kubernetes Monitoring (K8s-m8g)  

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A set of Grafana dashboards and Prometheus alerts to cover Kubernetes monitoring in an easy way using a drill-down principle.

# Getting Started

K8s-m8g helm chart is designed to be installed on top of the existing [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
and [loki-stack](https://github.com/grafana/loki/tree/master/production/helm/loki-stack) monitoring infrastructure.

Use a [K8s-m8g-stack](https://git.ifne.eu/dnation/k8s-m8g-stack) helm chart as a recommended way how to deploy K8s-m8g dashboards and alerts on your Kubernetes cluster. 

### Installation

Standalone installation on top of the existing monitoring infrastructure.

Prerequisites
* [Helm3](https://helm.sh/)

K8s-m8g helm chart is currently hosted in the public [ifne](https://www.ifne.eu/) helm repository.
```bash
# Add ifne helm repository
helm repo add ifne https://nexus.ifne.eu/repository/ifne-helm-public/
helm repo update

# Install K8s-m8g
kubectl create namespace monitoring
helm install k8s-m8g ifne/k8s-m8g --namespace monitoring
```

# Contribution guidelines

If you want to contribute to the K8s-m8g project, be sure to review the
[contribution guidelines](CONTRIBUTING.md). This project adheres to K8s-m8g's
[code of conduct](CODE_OF_CONDUCT.md). When participating, you are required to abide by the code of conduct.

We use GitHub issues to manage requests and bugs, please visit our discussion forum if you have any questions.

# Project Background

K8s-m8g project is developed, maintained and used in production by [dNation](https://www.dnation.tech/) professionals 
to simplify their day-to-day monitoring tasks.  
The development of K8s-m8g was transformed to an open source project in October 2020.
