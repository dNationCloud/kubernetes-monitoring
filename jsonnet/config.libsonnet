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

/* Configuration file */

{
  _config+:: {

    dashboardIDs: {
      // dNation dashboards
      k8sMonitoring: 'k8smonitoring',
      alertOverview: 'alertoverview',
      nodeOverview: 'nodeoverview',
      jobOverview: 'joboverview',
      podOverview: 'podoverview',
      statefulSetOverview: 'statefulsetoverview',
      pvcOverview: 'pvcoverview',
      nodeExporter: 'nodeexporter',
      containerOverview: 'containeroverview',
      deploymentOverview: 'deploymentoverview',
      daemonSetOverview: 'daemonsetoverview',
      containerDetail: 'containerdetail',
      diskOverview: 'diskoverview',
      memoryOverview: 'memoryoverview',
      memoryNamespaceOverview: 'memorynamespaceoverview',
      networkOverview: 'networkoverview',
      networkNamespaceOverview: 'networknamespaceoverview',
      cpuOverview: 'cpuoverview',
      cpuNamespaceOverview: 'cpunamespaceoverview',

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

      // Apps and hosts dashboards
      pythonFlask: 'pythonflask',
      javaActuator: 'javaactuator',
      cadvisor: 'cadvisor',
    },

    dashboardSelectors: {
      apiServer: 'job="apiserver"',
      controllerManager: 'job="kube-controller-manager"',
      etcd: 'job="kube-etcd"',
      kubelet: 'job="kubelet"',
      scheduler: 'job="kube-scheduler"',
      proxy: 'job="kube-proxy"',
    },

    dashboardCommon: {
      tags: {
        k8sMonitoring: ['k8s', 'monitoring', 'L1'],
        k8sOverview: ['k8s', 'overview', 'L2'],
        k8sSystem: ['k8s', 'system', 'L2'],
        k8sNodeExporter: ['k8s', 'nodeexporter', 'L3'],
        k8sPVC: ['k8s', 'pvc', 'L3'],
        k8sStateful: ['k8s', 'statefulset', 'L3'],
        k8sDetail: ['k8s', 'detail', 'view', 'L3'],
        k8sApps: ['k8s', 'app'],
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
        pink: '#fce2de',  // pink
        purple: '#a352cc',  // semi-dark-purple
        yellow: '#fade2a',  // yellow
        blue: '#5794f2',  // blue
        lightblue: '#8ab8ff',  // light-blue
      },
      dataLinkCommonArgs: 'refresh=%s&var-datasource=$datasource&var-cluster=$cluster&from=$__from&to=$__to' % [self.refresh],
      templateRefresh: 'time',  // on time range change
      templateSort: 5,  // case insensitive ascent sort
    },

    isLoki: true,

    ruleCommon: {
      alertNamePrefix: 'KubernetesMonitoring',
    },

    thresholds: {
      criticalPanel: {
        operator: '>=',
        critical: 1,
      },
      warningPanel: {
        operator: '>=',
        warning: 1,
      },
      k8s: {
        operator: '<',
        warning: 99,
        critical: 95,
      },
      pvc: {
        operator: '>=',
        warning: 85,
        critical: 97,
      },
      controlPlane: {
        operator: '<',
        critical: 1,
      },
      node: {
        operator: '>=',
        warning: 75,
        critical: 90,
      },
      networkErrors: {
        operator: '>=',
        warning: 10,
        critical: 15,
      },
    },

  },
}
