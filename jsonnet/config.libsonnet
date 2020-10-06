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

/* Configuration file */

{
  _config+:: {

    dashboardIDs: {
      // dNation dashboards
      k8sMonitoring: 'k8smonitoring',
      alertDetail: 'alertdetail',
      nodeDetail: 'nodedetail',
      jobDetail: 'jobdetail',
      podDetail: 'poddetail',
      statefulSetDetail: 'statefulsetdetail',
      pvcDetail: 'pvcdetail',
      nodeExporter: 'nodeexporter',
      containerDetail: 'containerdetail',
      deploymentDetail: 'deploymentdetail',
      logs: 'logs',
      diskDetail: 'diskdetail',
      memoryDetail: 'memorydetail',
      memoryNamespaceDetail: 'memorynamespacedetail',
      networkDetail: 'networkdetail',
      networkNamespaceDetail: 'networknamespacedetail',
      cpuDetail: 'cpudetail',

      // Kube system dashboards
      controllerManager: 'controllermanager',
      scheduler: 'scheduler',
      kubelet: 'kubelet',
      apiServer: 'apiserver',
      proxy: 'proxy',
      etcd: 'etcd',

      // Kube compute dashboards
      statefulSet: 'statefulset',

      // Kube pvc dashboard
      persistentVolumes: 'persistentvolumes',

    },

    dashboardSelectors: {
      stateMetrics: 'job="kube-state-metrics"',
      apiServer: 'job="apiserver"',
      controllerManager: 'job="kube-controller-manager"',
      etcd: 'job="kube-etcd"',
      kubelet: 'job="kubelet"',
      scheduler: 'job="kube-scheduler"',
      proxy: 'job="kube-proxy"',
    },

    dashboardDirs: {
      enable: false,
      basePath: '/var/lib/grafana/dashboards/',

      // K8s dashboards
      k8sPath: self.basePath + 'k8s',
      'k8s-monitoring.json': self.k8sPath,
      'alert-detail.json': self.k8sPath,
      'node-detail.json': self.k8sPath,
      'job-detail.json': self.k8sPath,
      'statefulset-detail.json': self.k8sPath,
      'pvc-detail.json': self.k8sPath,
      'node-exporter.json': self.k8sPath,
      'container-detail.json': self.k8sPath,
      'deployment-detail.json': self.k8sPath,
      'disk-detail.json': self.k8sPath,
      'memory-detail.json': self.k8sPath,
      'memory-namespace-detail.json': self.k8sPath,
      'network-detail.json': self.k8sPath,
      'network-namespace-detail.json': self.k8sPath,
      'cpu-detail.json': self.k8sPath,
      'pod-detail.json': self.k8sPath,
      'logs.json': self.k8sPath,

      // Kube system dashboards
      kubeSystemPath: self.basePath + 'kube_system',
      'controller-manager.json': self.kubeSystemPath,
      'scheduler.json': self.kubeSystemPath,
      'kubelet.json': self.kubeSystemPath,
      'api-server.json': self.kubeSystemPath,
      'proxy.json': self.kubeSystemPath,
      'etcd.json': self.kubeSystemPath,

      // Kube compute dashboards
      kubeComputePath: self.basePath + 'kube_compute',
      'statefulset.json': self.kubeComputePath,

      // Kube pvc dashboards
      pvcPath: self.basePath + 'kube_pvc',
      'pvc.json': self.pvcPath,
    },

    dashboardCommon: {
      tags: {
        k8sMonitoring: ['k8s', 'monitoring', 'L1'],
        k8sDetail: ['k8s', 'detail', 'L2'],
        k8sSystem: ['k8s', 'system', 'L2'],
        k8sNodeExporter: ['k8s', 'node', 'L3'],
        k8sPVC: ['k8s', 'compute', 'pvc', 'L3'],
        k8sStateful: ['k8s', 'compute', 'statefulset', 'L3'],
        k8sLogs: ['k8s', 'compute', 'logs', 'pod', 'view', 'L3'],
      },
      tooltip: 'shared_crosshair',
      editable: true,
      refresh: '10s',
      time_from: 'now-5m',
      color: {
        red: '#e02f44',  // semi-dark-red
        orange: '#ff780a',  // semi-dark-orange
        green: '#56a64b',  // semi-dark-green
        white: '#ffffff',  // white
        black: '#000000',  // black
      },
      dataLinkCommonArgs: 'refresh=%s&var-datasource=$datasource&var-cluster=$cluster&from=$__from&to=$__to' % [self.refresh],
      templateRefresh: 'time',  // on time range change
      templateSort: 5,  // case insensitive ascent sort
    },

    isLoki: true,

  },
}
