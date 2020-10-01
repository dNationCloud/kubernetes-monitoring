/*
  Copyright 2020 The K8s-m8g Authors. All Rights Reserved.
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

(import '../config.libsonnet') +

// dNation dashboards
(import 'k8s/k8s-monitoring.libsonnet') +
(import 'k8s/alert-detail.libsonnet') +
(import 'k8s/node-detail.libsonnet') +
(import 'k8s/job-detail.libsonnet') +
(import 'k8s/statefulset-detail.libsonnet') +
(import 'k8s/pvc-detail.libsonnet') +
(import 'k8s/node-exporter.libsonnet') +
(import 'k8s/container-detail.libsonnet') +
(import 'k8s/deployment-detail.libsonnet') +
(import 'k8s/disk-detail.libsonnet') +
(import 'k8s/memory-detail.libsonnet') +
(import 'k8s/memory-namespace-detail.libsonnet') +
(import 'k8s/network-detail.libsonnet') +
(import 'k8s/network-namespace-detail.libsonnet') +

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
(import 'k8s/pvc.libsonnet')
