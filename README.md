<a href="https://dNation.cloud/"><img src="https://storage.googleapis.com/ifne.eu/public/icons/dnation.png" width="250" alt="dNationCloud"></a>

# dNation Kubernetes Monitoring

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

TODO Insert video

A set of Grafana dashboards and Prometheus alerts written in [Jsonnet](https://jsonnet.org/). This Monitoring following 3 basic design principles:

1. `Intuitive` - Green, orange and red colors signaling whether or not your action is needed
1. `Drill-down` - if you want details why is something green, orange or red, just click it
1. `Relevant information only` - provide only metrics relevant for this particular area of interest and drill-down level, side-by-side with logs (experimental feature)

Monitoring targets are:

| Kubernetes | Hosts (TBD) | Applications (TBD) |
|:----------:|:-----------:|:------------------:|
| ![Kubernetes](docs/images/kubernetes-monitoring.png) | ![Hosts](docs/images/host-monitoring.png) | ![Applications](docs/images/app-monitoring.png) |

This project has been developed, maintained and used in production by professionals to simplify their day-to-day monitoring tasks and reduce incident reaction time.

# Full Installation
In case your current Kubernetes installation doesn't contain Prometheus, Grafana or Loki, please install [dNation Kubernetes Monitoring Stack](https://artifacthub.io/packages/helm/dnationcloud/dnation-kubernetes-monitoring-stack) helm chart.

# Dashboards and Alerts only Installation
In case your current Kubernetes installation already contains Prometheus, Grafana and Loki, please follow [here](GETTING_STARTED.md).

# Contribution guidelines

If you want to contribute, please read following:
1. [Contribution Guidelines](CONTRIBUTING.md)
1. [Code of Conduct](CODE_OF_CONDUCT.md)
1. [How To](helpers/README.md) simplify your local development

We use GitHub issues to manage requests and bugs, please visit our discussion forum if you have any questions.
