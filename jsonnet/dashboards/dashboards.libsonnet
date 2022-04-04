/*
  Copyright 2020 The dNation Kubernetes Monitoring Authors. All Rights Reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

(import '../util.libsonnet') +
(import 'grafana-templates.libsonnet') +

// dNation dashboards
(import 'k8s/k8s-monitoring.libsonnet') +
(import 'k8s/alert-overview.libsonnet') +
(import 'k8s/node-exporter.libsonnet') +
(import 'k8s/memory-namespace-overview.libsonnet') +
(import 'k8s/network-namespace-overview.libsonnet') +
(import 'k8s/container-detail.libsonnet') +
(import 'k8s/cpu-namespace-overview.libsonnet') +
(import 'k8s/k8s-overview-dashboards.libsonnet') +
(import 'k8s/node-overview-dashboards.libsonnet') +

// Kube system dashboards
(import 'k8s/controller-manager.libsonnet') +
(import 'k8s/scheduler.libsonnet') +
(import 'k8s/kubelet.libsonnet') +
(import 'k8s/api-server.libsonnet') +
(import 'k8s/etcd.libsonnet') +
(import 'k8s/proxy.libsonnet') +

// Kube compute dashboards
(import 'k8s/statefulset.libsonnet') +

// Kube pvc dashboards
(import 'k8s/pvc.libsonnet') +

// Hosts dashboards
(import 'hosts/host-monitoring.libsonnet') +
(import 'hosts/alert-overview.libsonnet') +

// Apps dashboards
(import 'apps/python-flask.libsonnet') +
(import 'apps/java-actuator.libsonnet') +
(import 'apps/php-fpm.libsonnet') +
(import 'apps/nginx-vts.libsonnet') +
(import 'apps/nginx-vts-enhanced.libsonnet') +
(import 'apps/nginx-vts-legacy.libsonnet') +
(import 'apps/nginx-vts-enhanced-legacy.libsonnet') +
(import 'apps/nginx-nrpe.libsonnet') +
(import 'apps/nginx-ingress.libsonnet') +
(import 'apps/cadvisor.libsonnet') +
(import 'apps/rabbitmq.libsonnet') +
(import 'apps/postfix.libsonnet') +
(import 'apps/autoscaler.libsonnet') +
(import 'apps/apache.libsonnet') +
(import 'apps/mysql-exporter.libsonnet') +
(import 'apps/websocket.libsonnet') +
(import 'apps/jvm.libsonnet') +

// VMs dashboards
(import 'vms/vm-monitoring.libsonnet') +
(import 'vms/alert-overview.libsonnet') +

// Monitoring dashboards
(import 'monitoring.libsonnet')
