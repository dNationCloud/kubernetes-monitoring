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

/* Default configuration file */
(import 'templates.libsonnet') +

{
  mergeConfig(defaultCfg, customCfg)::
    /**
     * Merge config
     *
     * Default configuration variables are taken from the `defaultConfig` configuration object
     * and from the command line top-level arguments. The top-level arguments have priority and
     * override the values read from default configuration according to JSON merge patch format RFC7396.
     *
     * @param defaultCfg default configuration variables taken from the `defaultConfig` object.
     * @param customCfg custom configuration variables taken from the command line top-level arguments.
     * @return merged config.
     */
    { _config:: std.mergePatch(defaultCfg, customCfg) },

  defaultConfig:: {
    grafanaDashboards: {
      isLoki: true,
      editable: true,
      tooltip: 'shared_crosshair',
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
        gray: '#858187', //gray
      },
      severityColors: {
        default: 'green',
        warning: 'orange',
        critical: 'red',
        invalid: 'black',  // invalid range is always from minus infinity to 'lowest' thredhold if it is defined
      },
      dataLinkCommonArgs: 'refresh=%s&var-datasource=$datasource&var-cluster=$cluster|&from=$__from&to=$__to' % [self.refresh],
      templateRefresh: 'time',  // on time range change
      templateSort: 5,  // case insensitive ascent sort
      ids: {
        // dNation dashboards
        k8sMonitoring: 'k8smonitoring',
        alertHostOverview: 'alerthostoverview',
        alertClusterOverview: 'alertclusteroverview',
        alertVMOverview: 'alertvmoverview',
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
        // Apps, hosts and vms dashboards
        vmMonitoring: 'vmmonitoring',
        hostMonitoring: 'hostmonitoring',
        pythonFlask: 'pythonflask',
        javaActuator: 'javaactuator',
        cAdvisor: 'cadvisor',
        phpFpm: 'phpfpm',
        nginxVts: 'nginxvts',
        nginxVtsEnhanced: 'nginxvtsenhanced',
        nginxNrpe: 'nginxnrpe',
        nginxIngress: 'nginxingress',
        rabbitmq: 'rabbitmq',
        postfix: 'postfix',
        autoscaler: 'autoscaler',
        apache: 'apache',
        mysqlExporter: 'mysqlexporter',
        //Monitoring dashboard
        monitoring: 'monitoring',
      },
      selectors: {
        apiServer: 'job="apiserver"',
        controllerManager: 'job="kube-controller-manager"',
        etcd: 'job="kube-etcd"',
        kubelet: 'job="kubelet"',
        scheduler: 'job="kube-scheduler"',
        proxy: 'job="kube-proxy"',
      },
      tags: {
        k8sMonitoring: ['k8s', 'monitoring', 'L1'],
        k8sOverview: ['k8s', 'overview', 'L2'],
        k8sSystem: ['k8s', 'system', 'L2'],
        k8sNodeExporter: ['k8s', 'nodeexporter', 'L3'],
        k8sPVC: ['k8s', 'pvc', 'L3'],
        k8sStatefulSet: ['k8s', 'statefulset', 'L3'],
        k8sContainer: ['k8s', 'container', 'L3'],
        k8sAppsMain: ['k8s', 'app', 'L0'],
        k8sApps: ['k8s', 'app', 'L1'],
        k8sVMs: ['k8s', 'vm', 'L2'],
        k8sHostsMain: ['k8s', 'host', 'L1'],
        k8sMonitoringMain: ['k8s', 'cluster', 'host', 'L0'],
      },
      constants: {
        infinity: 999999999,
        maxWarnings: 10000,
      },
    },
    templates: $.defaultTemplate,
    prometheusRules: {
      alertNamePrefix: 'KubernetesMonitoring',
      alertInterval: '5m',
      alertGroupCluster: 'Cluster',
      alertGroupClusterApp: 'ClusterApp',
      alertGroupClusterVM: 'ClusterVM',
      alertGroupClusterVMApp: 'ClusterVMApp',
      alertGroupHost: 'Host',
      alertGroupHostApp: 'HostApp',
    },
    //multiple cluster monitoring isn't supported yet
    clusterMonitoring: {
      enabled: true,
      clusters: [],
    },
    hostMonitoring: {
      enabled: false,
      hosts: [],
    },
  },
}
