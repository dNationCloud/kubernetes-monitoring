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
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

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
      // refresh: "" (empty string) to disable refresh
      refresh: '10s',
      time_from: 'now-5m',
      tooltip: grafana.dashboard.graphTooltip.withSharedCrosshair(),
      color: {
        red: '#e02f44',
        orange: '#ff780a',
        green: '#56a64b',
        white: '#ffffff',
        black: '#000000',
        pink: '#fce2de',
        purple: '#a352cc',
        yellow: '#fade2a',
        blue: '#5794f2',
        lightblue: '#8ab8ff', 
        lightgreen: '#96d98d', 
        lightyellow: '#ffee52',  
        lightorange: '#ffb357',  
        lightpurple: '#ca95e5',  
        darkyellow: '#f2cc0c', 
        darkblue: '#3274d9',
        darkred: '#a50000',
        darkerred: '#7e0505', 
        gray: '#858187',
      },
      severityColors: {
        default: 'green',
        warning: 'orange',
        critical: 'red',
        invalid: 'black',  // invalid range is always from minus infinity to 'lowest' thredhold if it is defined
      },
      dataLinkCommonArgs: 'var-datasource=$datasource&var-cluster=$cluster&from=$__from&to=$__to',
      dataLinkCommonArgsNoCluster: 'var-datasource=$datasource&from=$__from&to=$__to',
      dataLinkCommonArgsBlackbox: 'var-datasource=$datasource&var-target=$target&from=$__from&to=$__to',
      templateRefresh: 'onTime',  // onTime - on time range change, onLoad - on dashboard load
      templateSort: 5,  // case insensitive ascent sort
      ids: {
        // dNation dashboards
        k8sMonitoring: 'k8smonitoring',
        alertHostOverview: 'alerthostoverview',
        alertClusterOverview: 'alertclusteroverview',
        alertKaasOverview: 'alertkaasoverview',
        alertTestbedOverview: 'alerttestbedoverview',
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
        kaasL1Monitoring: 'kaasl1monitoring',
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
        lokiDistributed: 'loki-distributed',
        phpFpm: 'phpfpm',
        nginxVts: 'nginxvts',
        nginxVtsEnhanced: 'nginxvtsenhanced',
        nginxVtsLegacy: 'nginxvtslegacy',
        nginxVtsEnhancedLegacy: 'nginxvtsenhancedlegacy',
        nginxNrpe: 'nginxnrpe',
        nginxIngress: 'nginxingress',
        rabbitmq: 'rabbitmq-overview',
        postfix: 'postfix',
        autoscaler: 'autoscaler',
        apache: 'apache',
        mysqlExporter: 'mysqlexporter',
        websocket: 'websocket',
        jvm: 'jvm',
        prometheus: 'prometheus',
        sslExporter: 'ssl-exporter',
        vfioGPU: 'vfio-gpu',
        harbor: 'harbor',
        testbed: 'testbed',
        //Monitoring dashboard
        monitoring: 'monitoring',
        kaasMonitoring: 'kaas-monitoring',
        ceph: 'ceph',
        openstack: 'openstack',
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
        kaasMonitoring: ['kaas', 'monitoring', 'L1'],
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
        kaasMonitoringMain: ['kaas', 'cluster', 'L0'],
        testbed: ['testbed', 'L0'],
        testbedAlert: ['testbed', 'L1'],
      },
      constants: {
        infinity: 99999999999999999999999999999999,
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

    blackboxMonitoring: {
      enabled: false,
    },
    testbedMonitoring: {
      enabled: false,
    },
    kaasMonitoring: {
      enabled: false,
      clusters: [],
    },
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
