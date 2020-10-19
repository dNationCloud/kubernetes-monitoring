# Helpers

A set of scripts and configuration files which helps to simplify local development.

## Local development using KinD (Kubernetes in Docker)

Prerequisites

* [Kind](https://kind.sigs.k8s.io/)
* [Docker](https://www.docker.com/)
* [Helm3](https://helm.sh/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

### Build 

Grafana dashboards and Prometheus alerts are stored in the [jsonnet](https://jsonnet.org/) templates. 

Build a valid HELM templates from jsonnet templates is done by following steps:
- generate YAML files from jsonnet templates
- pretty print of generated YAML files - some escape characters provided by jsonnet build need to be removed to achieve valid HELM template format
  - pretty print is not yet supported by jsonnet library, see https://github.com/google/jsonnet/issues/821
```
# generate YAML files from jsonnet templates
docker run -u `id -u` --rm -t -v `pwd`:/src dnationcloud/jsonnet:latest jsonnet -c -m chart/templates/k8s-m8g -S jsonnet/helm.jsonnet
# pretty print of generated YAML files
find ./chart/templates/k8s-m8g/ -type f -regex '.*\.yaml' -print |  while read f; do docker run -u `id -u` --rm -t -v `pwd`:/src test:yq yq r -P "$f" > "$f"_tmp && mv "$f"_tmp "$f" || exit 1; done;
```

Build dashboard json files
```
mkdir dashboards
docker run -u `id -u` --rm -t -v `pwd`:/src dnationcloud/jsonnet:latest jsonnet -m dashboards jsonnet/dashboard.jsonnet
```

Jsonnet Formatter & Linter
```
find ./jsonnet/ -type f -regex '.*\.\(libsonnet\|jsonnet\)' -print |  while read f; do docker run -u `id -u` --rm -t -v `pwd`:/src dnationcloud/jsonnet:latest jsonnetfmt -i "$f" || exit 1; done;
find ./jsonnet/ -type f -regex '.*\.\(libsonnet\|jsonnet\)' -print |  while read f; do docker run -u `id -u` --rm -t -v `pwd`:/src dnationcloud/jsonnet:latest jsonnet-lint "$f" || exit 1; done;
```

HELM Linter
```
helm lint chart
```

Create KinD cluster
```bash
kind create cluster --config helpers/kind_cluster_config.yaml --image kindest/node:v1.19.1
```

Install K8s-m8g-stack (without K8s-m8g dependency)
* Grafana UI is exposed on port `5000`, see http://localhost:5000
* Prometheus UI is exposed on port `5001`, see http://localhost:5001
* Prometheus Alertmanager UI is exposed on port `5002`, see http://localhost:5002
```bash
# Add ifne helm repository
helm repo add ifne https://nexus.ifne.eu/repository/ifne-helm-public/
helm repo update

# Install K8s-m8g-stack without k8s-m8g chart
helm install k8s-m8g-stack ifne/k8s-m8g-stack -f helpers/values-kind.yaml 
```

Install K8s-m8g
```bash
helm install k8s-m8g chart --dependency-update
```
