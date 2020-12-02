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
      },
      dataLinkCommonArgs: 'refresh=%s&var-datasource=$datasource&var-cluster=$cluster|&from=$__from&to=$__to' % [self.refresh],
      templateRefresh: 'time',  // on time range change
      templateSort: 5,  // case insensitive ascent sort
      ids: {
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
        hostMonitoring: 'hostmonitoring',
        appMonitoring: 'appmonitoring',
        pythonFlask: 'pythonflask',
        javaActuator: 'javaactuator',
        cAdvisor: 'cadvisor',
        phpFpm: 'phpfpm',
        nginxVts: 'nginxvts',
        nginxNrpe: 'nginxnrpe',
        nginxIngress: 'nginxingress',
        rabbitmq: 'rabbitmq',
        postfix: 'postfix',
        autoscaler: 'autoscaler',
        apache: 'apache',
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
        k8sHostsMain: ['k8s', 'host', 'L1'],
      },
    },

    prometheusRules: {
      alertNamePrefix: 'KubernetesMonitoring',
      alertInterval: '5m',
      alertGroupApp: 'App',
      alertGroupCluster: 'Cluster',
      alertGroupHost: 'Host',
      alertGroupHostApp: 'HostApp',
    },

    commonThresholds: {
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
      controlPlane: {
        operator: '<',
        warning: 99,
        critical: 95,
      },
      node: {
        operator: '>=',
        warning: 75,
        critical: 90,
      },
    },
    templates: {
      nodeHealth: {
        expr: 'round(sum(kube_node_info{cluster=~"$cluster|"}) / (sum(kube_node_info{cluster=~"$cluster|"}) + sum(kube_node_spec_unschedulable{cluster=~"$cluster|"}) + sum(kube_node_status_condition{cluster=~"$cluster|", condition=~"DiskPressure|MemoryPressure|PIDPressure", status=~"true|unknown"})  + sum(kube_node_status_condition{cluster=~"$cluster|", condition="Ready", status=~"false|unknown"}) ) * 100)',
        thresholds: $.defaultConfig.commonThresholds.k8s,
      },
      runningPods: {
        expr: 'round(sum(kube_pod_status_phase{cluster=~"$cluster|", phase="Running"}) / (sum(kube_pod_status_phase{cluster=~"$cluster|", phase="Running"}) + sum(kube_pod_status_phase{cluster=~"$cluster|", phase="Pending"}) + sum(kube_pod_status_phase{cluster=~"$cluster|", phase="Failed"}) + sum(kube_pod_status_phase{cluster=~"$cluster|", phase="Unknown"})) * 100)',
        thresholds: $.defaultConfig.commonThresholds.k8s,
      },
      runningStatefulSets: {
        expr: 'round(sum(kube_statefulset_status_replicas_ready{cluster=~"$cluster|"}) / sum(kube_statefulset_status_replicas{cluster=~"$cluster|"}) * 100)',
        thresholds: $.defaultConfig.commonThresholds.k8s,
      },
      daemonSetsHealth: {
        expr: 'round((sum(kube_daemonset_updated_number_scheduled{cluster=~"$cluster|"}) + sum(kube_daemonset_status_number_available{cluster=~"$cluster|"})) / (2 * sum(kube_daemonset_status_desired_number_scheduled{cluster=~"$cluster|"})) * 100)',
        thresholds: $.defaultConfig.commonThresholds.k8s,
      },
      pvcBound: {
        expr: 'round(sum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster|", phase="Bound"}) / (\nsum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster|", phase="Bound"}) + sum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster|", phase="Pending"}) +\nsum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster|", phase="Lost"})\n) * 100)',
        thresholds: $.defaultConfig.commonThresholds.k8s,
      },
      deploymentsHealth: {
        expr: 'round((sum(kube_deployment_status_replicas_updated{cluster=~"$cluster|"}) + sum(kube_deployment_status_replicas_available{cluster=~"$cluster|"})) / (2 * sum(kube_deployment_status_replicas{cluster=~"$cluster|"})) * 100)',
        thresholds: $.defaultConfig.commonThresholds.k8s,
      },
      runningContainers: {
        expr: 'round(sum(kube_pod_container_status_running{cluster=~"$cluster|"}) / (sum(kube_pod_container_status_running{cluster=~"$cluster|"}) + sum(kube_pod_container_status_terminated_reason{cluster=~"$cluster|", reason!="Completed"}) + sum(kube_pod_container_status_waiting{cluster=~"$cluster|"})) * 100)',
        thresholds: $.defaultConfig.commonThresholds.k8s,
      },
      succeededJobs: {
        expr: 'round(sum(kube_job_status_succeeded{cluster=~"$cluster|"}) / (sum(kube_job_status_succeeded{cluster=~"$cluster|"}) + sum(kube_job_status_failed{cluster=~"$cluster|"})) * 100)',
        thresholds: $.defaultConfig.commonThresholds.k8s,
      },
      mostUtilizedPVC: {
        expr: 'max(sum(\n  ((kubelet_volume_stats_capacity_bytes{cluster=~"$cluster|"} - kubelet_volume_stats_available_bytes{cluster=~"$cluster|"}) / \n  kubelet_volume_stats_capacity_bytes{cluster=~"$cluster|"}) * 100\n) by (persistentvolumeclaim))',
        thresholds: {
          operator: '>=',
          warning: 85,
          critical: 97,
        },
      },
      apiServerHealth: {
        expr: '(sum(up{cluster=~"$cluster|", %(apiServer)s}) / count(up{cluster=~"$cluster|", %(apiServer)s})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
        thresholds: $.defaultConfig.commonThresholds.controlPlane,
      },
      controllerManagerHealth: {
        expr: '(sum(up{cluster=~"$cluster|", %(controllerManager)s}) / count(up{cluster=~"$cluster|", %(controllerManager)s})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
        thresholds: $.defaultConfig.commonThresholds.controlPlane,
      },
      etcdHealth: {
        expr: '(sum(up{cluster=~"$cluster|", %(etcd)s}) / count(up{cluster=~"$cluster|", %(etcd)s})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
        thresholds: $.defaultConfig.commonThresholds.controlPlane,
      },
      kubeletHealth: {
        expr: '(sum(up{cluster=~"$cluster|", %(kubelet)s, metrics_path="/metrics"}) / count(up{cluster=~"$cluster|", %(kubelet)s, metrics_path="/metrics"})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
        thresholds: $.defaultConfig.commonThresholds.controlPlane,
      },
      proxyHealth: {
        expr: '(sum(up{cluster=~"$cluster|", %(proxy)s}) / count(up{cluster=~"$cluster|", %(proxy)s})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
        thresholds: $.defaultConfig.commonThresholds.controlPlane,
      },
      schedulerHealth: {
        expr: '(sum(up{cluster=~"$cluster|", %(scheduler)s}) / count(up{cluster=~"$cluster|", %(scheduler)s})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
        thresholds: $.defaultConfig.commonThresholds.controlPlane,
      },
      nodeCpuUtilization: {
        expr: 'round((1 - (avg(irate(node_cpu_seconds_total{cluster=~"$cluster|", %(job)s, mode="idle"}[5m]) * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename) )) * 100)',
        thresholds: $.defaultConfig.commonThresholds.node,
      },
      nodeRamUtilization: {
        expr: 'round((1 - sum by (job, nodename) (node_memory_MemAvailable_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) / sum by (job, nodename) (node_memory_MemTotal_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info))) * 100)',
        thresholds: $.defaultConfig.commonThresholds.node,
      },
      nodeDiskUtilization: {
        expr: 'round((sum(node_filesystem_size_bytes{cluster=~"$cluster|", %(job)s, device!="rootfs"} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster|", %(job)s, device!="rootfs"} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) / ((sum(node_filesystem_size_bytes{cluster=~"$cluster|", %(job)s, device!="rootfs"} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster|", %(job)s, device!="rootfs"} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) + sum(node_filesystem_avail_bytes{cluster=~"$cluster|", %(job)s, device!="rootfs"} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) * 100  > 0)',
        thresholds: $.defaultConfig.commonThresholds.node,
      },
      nodeNetworkErrors: {
        expr: 'sum(rate(node_network_transmit_errs_total{cluster=~"$cluster|", %(job)s, device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"} [5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename) + sum(rate(node_network_receive_errs_total{cluster=~"$cluster|", %(job)s, device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename)',
        thresholds: {
          operator: '>=',
          warning: 10,
          critical: 15,
        },
      },
      pythonFlask: {
        expr: '(sum by (job) (rate(flask_http_request_duration_seconds_count{cluster=~"$cluster|", %(job)s,status!~"[4-5].*"}[5m])) / sum by (job) (rate(flask_http_request_duration_seconds_count{cluster=~"$cluster|", %(job)s}[5m])) * 100) > 0 OR (sum by (job) (rate(flask_http_request_duration_seconds_count{cluster=~"$cluster|", %(job)s}[5m])) + 100)',
        thresholds: {
          operator: '<',
          critical: 85,
          warning: 95,
        },
      },
      javaActuator: {
        expr: '(sum by (job) (jvm_memory_used_bytes{cluster=~"$cluster|", %(job)s, area="heap"})*100/sum  by (job) (jvm_memory_max_bytes{cluster=~"$cluster|", %(job)s, area="nonheap"}) > sum  by (job) (jvm_memory_used_bytes{cluster=~"$cluster|", %(job)s, area="nonheap"})*100/sum  by (job) (jvm_memory_max_bytes{cluster=~"$cluster|", %(job)s, area="heap"}) or (sum  by (job) (jvm_memory_used_bytes{cluster=~"$cluster|", %(job)s, area="nonheap"})*100)/sum by (job) (jvm_memory_max_bytes{cluster=~"$cluster|", %(job)s, area="heap"}))',
        thresholds: {
          operator: '>=',
          critical: 90,
          warning: 75,
        },
      },
      nginxIngress: {
        expr: '(sum by (job) (rate(nginx_ingress_controller_requests{cluster=~"$cluster|", %(job)s, status!~"[4-5].*"}[5m])) / sum by (job) (rate(nginx_ingress_controller_requests{cluster=~"$cluster|", %(job)s}[5m])) * 100) > 0 OR (sum by (job) (rate(nginx_ingress_controller_requests{cluster=~"$cluster|", %(job)s}[5m])) + 100)',
        thresholds: {
          operator: '<',
          critical: 85,
          warning: 95,
        },
      },
      nginxVts: {
        expr: '(sum by (job) (rate(nginx_server_requests{cluster=~"$cluster|", %(job)s, code!~"[4-5].*", code!="total"}[5m])) / sum by (job) (rate(nginx_server_requests{cluster=~"$cluster|", %(job)s, code!="total"}[5m])) * 100) > 0 OR (sum by (job) (rate(nginx_server_requests{cluster=~"$cluster|", %(job)s}[5m])) + 100)',
        thresholds: {
          operator: '<',
          critical: 85,
          warning: 95,
        },
      },
      autoscaler: {
        expr: '(sum by (job) (autoscaler_healthy{cluster=~"$cluster|", %(job)s}) / sum by (job) (autoscaler_instances{cluster=~"$cluster|", %(job)s}) * 100) > 0 OR (sum by (job) (autoscaler_instances{cluster=~"$cluster|", %(job)s}) + 100)',
        thresholds: {
          operator: '<',
          critical: 85,
          warning: 95,
        },
      },
      postfix: {
        expr: '(sum by (job) (postfix_size{cluster=~"$cluster|", %(job)s}))',
        unit: 'emails',
        thresholds: {
          operator: '>=',
          warning: 5,
          critical: 10,
        },
      },
      defaultApp: {
        expr: '(sum(up{%(job)s}) / count(up{cluster=~"$cluster|", %(job)s}))*100',
        thresholds: {
          operator: '<',
          warning: 99,
          critical: 95,
        },
      },
    },
    appMonitoring: {
      enabled: false,
      apps: [],
    },
    hostMonitoring: {
      enabled: false,
      hosts: [],
    },
  },
}
