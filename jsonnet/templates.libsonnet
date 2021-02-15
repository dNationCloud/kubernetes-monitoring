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

/* Default templates file */

{
  defaultTemplate:: {
    local defaultTemplate = self,
    local utils = (import 'util.libsonnet'),

    getTemplatesApp(group, templates):: {
      local alert =
        if std.objectHas(templates[template], 'alert') then
          {
            name: templates[template].alert.name % { prefix: group },
            message: templates[template].alert.message % { prefix: group },
            customLables: { alertgroup: group },
          }
        else
          {},
      [template]: std.mergePatch(
        templates[template], {
          alert: alert,
        }
      )
      for template in std.objectFields(templates)
    },

    templateBases: {
      baseStatsTemplate: {
        enabled: true,
        default: true,
        panel: {
          title: 'error must be overwritten',
          description: '',
          datasource: '$datasource',
          colorMode: 'background',
          graphMode: 'area',
          unit: 'percent',
          decimals: null,
          dataLinks: [],
          mappings: [],
          expr: '',
          thresholds: {},
          gridPos: {
            x: 'error must be overwritten',
            y: 'error must be overwritten',
            w: 6,
            h: 3,
          },
        },
        alert: {},
      },
      baseTableTemplate: {
        enabled: true,
        default: true,
        panel: {
          title: 'error must be overwritten',
          description: '',
          datasource: '$datasource',
          styles: [],
          sort: {},
          expr: [],
          gridPos: {
            x: 0,
            y: 1,
            w: 24,
            h: 19,
          },
        },
      },
      baseAlert: {
        name: 'error must be overwritten',
        message: '',
        customLables: {},
        expr: '',
        linkGetParams: '',
        thresholds: {},
      },
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
      app: {
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
    L1: {
      k8s: {
        local k8sCustomLables = { alertgroup: $.defaultConfig.prometheusRules.alertGroupCluster },
        targetDown: {
          panel: null,
          alert: {
            name: 'ClusterTargetDown',
            message: '{{ printf "%.4g" $value }}% of the {{ $labels.job }}/{{ $labels.service }} targets in {{ $labels.namespace }} namespace are down.',
            customLables: k8sCustomLables,
            expr: '100 * (count by(job, namespace, service) (up{alertGroup!="Host"} == 0) / count by(job, namespace, service) (up{alertGroup!="Host"}))',
            thresholds: {
              operator: '>=',
              warning: 10,
              critical: 90,
            },
          },
        },
        nodeHealth: {
          local expr = 'round(sum(kube_node_info{cluster=~"$cluster|"}) / (sum(kube_node_info{cluster=~"$cluster|"}) + sum(kube_node_spec_unschedulable{cluster=~"$cluster|"}) + sum(kube_node_status_condition{cluster=~"$cluster|", condition=~"DiskPressure|MemoryPressure|PIDPressure", status=~"true|unknown"})  + sum(kube_node_status_condition{cluster=~"$cluster|", condition="Ready", status=~"false|unknown"}) ) * 100)',
          local thresholds = defaultTemplate.commonThresholds.k8s,
          linkTo: ['nodeOverviewTable'],
          panel: {
            title: 'Nodes Health',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 0,
              y: 5,
            },
          },
          alert: {
            name: 'NodesHealthLow',
            message: 'Nodes Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        runningPods: {
          local expr = 'round(sum(kube_pod_status_phase{cluster=~"$cluster|", phase="Running"}) / (sum(kube_pod_status_phase{cluster=~"$cluster|", phase="Running"}) + sum(kube_pod_status_phase{cluster=~"$cluster|", phase="Pending"}) + sum(kube_pod_status_phase{cluster=~"$cluster|", phase="Failed"}) + sum(kube_pod_status_phase{cluster=~"$cluster|", phase="Unknown"})) * 100)',
          local thresholds = defaultTemplate.commonThresholds.k8s,
          linkTo: ['podOverviewTable'],
          panel: {
            title: 'Running Pods',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 12,
              y: 5,
            },
          },
          alert: {
            name: 'RunningPodsHealthLow',
            message: 'Pods Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        runningStatefulSets: {
          local expr = 'round(sum(kube_statefulset_status_replicas_ready{cluster=~"$cluster|"}) / sum(kube_statefulset_status_replicas{cluster=~"$cluster|"}) * 100)',
          local thresholds = defaultTemplate.commonThresholds.k8s,
          linkTo: ['statefulSetOverviewTable'],
          panel: {
            title: 'Running StatefulSets',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 6,
              y: 5,
            },
          },
          alert: {
            name: 'RunningStatefulSetsHealthLow',
            message: 'StatefulSets Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        daemonSetsHealth: {
          local expr = 'round((sum(kube_daemonset_updated_number_scheduled{cluster=~"$cluster|"}) + sum(kube_daemonset_status_number_available{cluster=~"$cluster|"})) / (2 * sum(kube_daemonset_status_desired_number_scheduled{cluster=~"$cluster|"})) * 100)',
          local thresholds = defaultTemplate.commonThresholds.k8s,
          linkTo: ['daemonSetOverviewTable'],
          panel: {
            title: 'DaemonSets Health',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 6,
              y: 8,
            },
          },
          alert: {
            name: 'RunningDaemonSetsHealthLow',
            message: 'DaemonSets Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        pvcBound: {
          local expr = 'round(sum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster|", phase="Bound"}) / (\nsum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster|", phase="Bound"}) + sum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster|", phase="Pending"}) +\nsum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster|", phase="Lost"})\n) * 100)',
          local thresholds = defaultTemplate.commonThresholds.k8s {
            lowest: 0,  // invalid range is always from minus infinity to 'lowest' thredhold
          },
          linkTo: ['pvcOverviewTable'],
          panel: {
            title: 'PVC Bound',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: '%s OR on() vector(-1)' % expr,
            thresholds: thresholds,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              x: 18,
              y: 8,
              w: 3,
            },
          },
          alert: {
            name: 'PVCBoundRateLow',
            message: 'PVC Bound Rate Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        deploymentsHealth: {
          local expr = 'round((sum(kube_deployment_status_replicas_updated{cluster=~"$cluster|"}) + sum(kube_deployment_status_replicas_available{cluster=~"$cluster|"})) / (2 * sum(kube_deployment_status_replicas{cluster=~"$cluster|"})) * 100)',
          local thresholds = defaultTemplate.commonThresholds.k8s,
          linkTo: ['deploymentOverviewTable'],
          panel: {
            title: 'Deployments Health',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 0,
              y: 8,
            },
          },
          alert: {
            name: 'RunningDeploymentsHealthLow',
            message: 'Running Deployments Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        runningContainers: {
          local expr = 'round(sum(kube_pod_container_status_running{cluster=~"$cluster|"}) / (sum(kube_pod_container_status_running{cluster=~"$cluster|"}) + sum(kube_pod_container_status_terminated_reason{cluster=~"$cluster|", reason!="Completed"}) + sum(kube_pod_container_status_waiting{cluster=~"$cluster|"})) * 100)',
          local thresholds = defaultTemplate.commonThresholds.k8s,
          linkTo: ['containerOverviewTable'],
          panel: {
            title: 'Running Containers',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 12,
              y: 8,
            },
          },
          alert: {
            name: 'RunningContainersHealthLow',
            message: 'Running Containers Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        succeededJobs: {
          local expr = 'round(sum(kube_job_status_succeeded{cluster=~"$cluster|"}) / (sum(kube_job_status_succeeded{cluster=~"$cluster|"}) + sum(kube_job_status_failed{cluster=~"$cluster|"})) * 100)',
          local thresholds = defaultTemplate.commonThresholds.k8s {
            lowest: 0,  // invalid range is always from minus infinity to 'lowest' thredhold
          },
          linkTo: ['jobOverviewTable'],
          panel: {
            title: 'Succeeded Jobs',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: '%s OR on() vector(-1)' % expr,
            thresholds: thresholds,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              x: 18,
              y: 5,
            },
          },
          alert: {
            name: 'SucceededJobsRateLow',
            message: 'Succeeded Jobs Rate Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        mostUtilizedPVC: {
          local expr = 'sum(((kubelet_volume_stats_capacity_bytes{cluster=~"$cluster|"} - kubelet_volume_stats_available_bytes{cluster=~"$cluster|"}) / kubelet_volume_stats_capacity_bytes{cluster=~"$cluster|"}) * 100) by (persistentvolumeclaim)',
          local thresholds = {
            operator: '>=',
            warning: 85,
            critical: 97,
            lowest: 0,  // invalid range is always from minus infinity to 'lowest' thredhold
          },
          panel: {
            title: 'Most Utilized PVC',
            dataLinks: [{ title: 'K8s Overview', url: '/d/%s?%s' % [$.defaultConfig.grafanaDashboards.ids.pvcOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] }],
            expr: 'max(%s) OR on() vector(-1)' % expr,
            thresholds: thresholds,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              x: 21,
              y: 8,
              w: 3,
            },
          },
          alert: {
            name: 'PVCUtilizationHigh',
            message: '"{{ $labels.persistentvolumeclaim }}": High PVC Utilization {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            linkGetParams: 'var-volume={{ $labels.persistentvolumeclaim }}',
            thresholds: thresholds,
          },
        },
        apiServerHealth: {
          local expr = '(sum(up{cluster=~"$cluster|", %(apiServer)s}) / count(up{cluster=~"$cluster|", %(apiServer)s})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
          local thresholds = defaultTemplate.commonThresholds.controlPlane,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.apiServer],
          panel: {
            title: 'API Server',
            //dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs, dashboard:: $.defaultConfig.grafanaDashboards.ids.apiServer }],
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 0,
              y: 12,
              w: 4,
            },
          },
          alert: {
            name: 'ClusterApiServerHealthLow',
            message: 'Cluster Api Server Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        controllerManagerHealth: {
          local expr = '(sum(up{cluster=~"$cluster|", %(controllerManager)s}) / count(up{cluster=~"$cluster|", %(controllerManager)s})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
          local thresholds = defaultTemplate.commonThresholds.controlPlane,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.controllerManager],
          panel: {
            title: 'Controller Manager',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 4,
              y: 12,
              w: 4,
            },
          },
          alert: {
            name: 'ClusterControllerManagerHealthLow',
            message: 'Cluster Controller Manager Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        etcdHealth: {
          local expr = '(sum(up{cluster=~"$cluster|", %(etcd)s}) / count(up{cluster=~"$cluster|", %(etcd)s})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
          local thresholds = defaultTemplate.commonThresholds.controlPlane,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.etcd],
          panel: {
            title: 'Etcd',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 8,
              y: 12,
              w: 4,
            },
          },
          alert: {
            name: 'ClusterEtcdHealthLow',
            message: 'Cluster Etcd Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        kubeletHealth: {
          local expr = '(sum(up{cluster=~"$cluster|", %(kubelet)s, metrics_path="/metrics"}) / count(up{cluster=~"$cluster|", %(kubelet)s, metrics_path="/metrics"})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
          local thresholds = defaultTemplate.commonThresholds.controlPlane,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.kubelet],
          panel: {
            title: 'Kubelet',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 12,
              y: 12,
              w: 4,
            },
          },
          alert: {
            name: 'ClusterKubeletHealthLow',
            message: 'Cluster Kubelet Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        proxyHealth: {
          local expr = '(sum(up{cluster=~"$cluster|", %(proxy)s}) / count(up{cluster=~"$cluster|", %(proxy)s})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
          local thresholds = defaultTemplate.commonThresholds.controlPlane,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.proxy],
          panel: {
            title: 'Proxy',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 16,
              y: 12,
              w: 4,
            },
          },
          alert: {
            name: 'ClusterProxyHealthLow',
            message: 'Cluster Proxy Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        schedulerHealth: {
          local expr = '(sum(up{cluster=~"$cluster|", %(scheduler)s}) / count(up{cluster=~"$cluster|", %(scheduler)s})) * 100' % $.defaultConfig.grafanaDashboards.selectors,
          local thresholds = defaultTemplate.commonThresholds.controlPlane,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.scheduler],
          panel: {
            title: 'Scheduler',
            dataLinks: [{ title: 'K8s Overview', url: '/d/{}?%s' % $.defaultConfig.grafanaDashboards.dataLinkCommonArgs }],
            expr: expr,
            thresholds: thresholds,
            gridPos: {
              x: 20,
              y: 12,
              w: 4,
            },
          },
          alert: {
            name: 'ClusterSchedulerHealthLow',
            message: 'Cluster Scheduler Health Low {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr,
            thresholds: thresholds,
          },
        },
        mostUtilizedNodeCPU: {
          local expr = 'round((1 - (avg(irate(node_cpu_seconds_total{cluster=~"$cluster|", %(job)s, mode="idle"}[5m]) * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename) )) * 100)',
          local thresholds = defaultTemplate.commonThresholds.node,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.nodeExporter],
          panel: {
            title: 'Most Utilized Node',
            dataLinks: [
              { title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$.defaultConfig.grafanaDashboards.ids.cpuOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
              { title: 'K8s Overview', url: '/d/%s?%s' % [$.defaultConfig.grafanaDashboards.ids.cpuNamespaceOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
            ],
            expr: 'max(%s)' % expr % { job: 'job=~"$job"' },
            thresholds: thresholds,
            gridPos: {
              x: 3,
              y: 17,
              w: 3,
            },
          },
          alert: {
            name: 'ClusterNodeCPUUtilizationHigh',
            message: 'Cluster {{ $labels.nodename }}: High CPU Utilization {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr % { job: 'job=~"node-exporter"' },
            linkGetParams: 'var-instance={{ $labels.nodename }}',
            thresholds: thresholds,
          },
        },
        mostUtilizedNodeRAM: {
          local expr = 'round((1 - sum by (job, nodename) (node_memory_MemAvailable_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) / sum by (job, nodename) (node_memory_MemTotal_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info))) * 100)',
          local thresholds = defaultTemplate.commonThresholds.node,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.nodeExporter],
          panel: {
            title: 'Most Utilized Node',
            description: 'The percentage of the memory utilization is calculated by:\n```\n1 - (<memory available>/<memory total>)\n```',
            dataLinks: [
              { title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$.defaultConfig.grafanaDashboards.ids.memoryOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
              { title: 'K8s Overview', url: '/d/%s?%s' % [$.defaultConfig.grafanaDashboards.ids.memoryNamespaceOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
            ],
            expr: 'max(%s)' % expr % { job: 'job=~"$job"' },
            thresholds: thresholds,
            gridPos: {
              x: 9,
              y: 17,
              w: 3,
            },
          },
          alert: {
            name: 'ClusterNodesRAMUtilizationHigh',
            message: 'Cluster node {{ $labels.nodename }}: High RAM Utilization {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr % { job: 'job=~"node-exporter"' },
            linkGetParams: 'var-instance={{ $labels.nodename }}',
            thresholds: thresholds,
          },
        },
        mostUtilizedNodeDisk: {
          local expr = 'round((sum(node_filesystem_size_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) / ((sum(node_filesystem_size_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) + sum(node_filesystem_avail_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) * 100)',
          local thresholds = defaultTemplate.commonThresholds.node,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.nodeExporter],
          panel: {
            title: 'Most Utilized Node',
            description: 'The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition. See the list of explicitly ignored mount points and file systems [here](https://github.com/dNationCloud/kubernetes-monitoring-stack/blob/main/chart/values.yaml)',
            dataLinks: [{ title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$.defaultConfig.grafanaDashboards.ids.diskOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] }],
            expr: 'max(%s)' % expr % { job: 'job=~"$job"' },
            thresholds: thresholds,
            gridPos: {
              x: 15,
              y: 17,
              w: 3,
            },
          },
          alert: {
            name: 'ClusterHostDiskUtilizationHigh',
            message: 'Cluster node {{ $labels.nodename }}: High Disk Utilization {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr % { job: 'job=~"node-exporter"' },
            linkGetParams: 'var-instance={{ $labels.nodename }}',
            thresholds: thresholds,
          },
        },
        mostUtilizedNodeNetworkErrors: {
          local expr = 'sum(rate(node_network_transmit_errs_total{cluster=~"$cluster|", %(job)s, device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"} [5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename) + sum(rate(node_network_receive_errs_total{cluster=~"$cluster|", %(job)s, device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename)',
          local thresholds = {
            operator: '>=',
            warning: 10,
            critical: 15,
          },
          linkTo: [$.defaultConfig.grafanaDashboards.ids.nodeExporter],
          panel: {
            title: 'Most Affected Node',
            dataLinks: [
              { title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$.defaultConfig.grafanaDashboards.ids.networkOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
              { title: 'K8s Overview', url: '/d/%s?%s' % [$.defaultConfig.grafanaDashboards.ids.networkNamespaceOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
            ],
            expr: 'max(%s)' % expr % { job: 'job=~"$job"' },
            unit: 'pps',
            thresholds: thresholds,
            gridPos: {
              x: 21,
              y: 17,
              w: 3,
            },
          },
          alert: {
            name: 'ClusterHostNetworkErrorsHigh',
            message: 'Cluster node {{ $labels.nodename }}: High Network Errors Count {{ $value }}%',
            customLables: k8sCustomLables,
            expr: expr % { job: 'job=~"node-exporter"' },
            linkGetParams: 'var-instance={{ $labels.nodename }}',
            thresholds: thresholds,
          },
        },
        overallUtilizationCPU: {
          local expr = 'round((1 - (avg(irate(node_cpu_seconds_total{cluster=~"$cluster|", %(job)s, mode="idle"}[5m]) * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename) )) * 100)',
          local thresholds = defaultTemplate.commonThresholds.node,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.cpuOverview],
          panel: {
            title: 'Overall Utilization',
            dataLinks: [
              { title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$.defaultConfig.grafanaDashboards.ids.cpuOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
              { title: 'K8s Overview', url: '/d/%s?%s' % [$.defaultConfig.grafanaDashboards.ids.cpuNamespaceOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
            ],
            expr: 'avg(%s)' % expr % { job: 'job=~"$job"' },
            thresholds: thresholds,
            gridPos: {
              x: 0,
              y: 17,
              w: 3,
            },
          },
          alert: {
            name: 'ClusterCPUOverallHigh',
            message: 'Cluster High CPU Overall Utilization {{ $value }}%',
            expr: 'avg(%s)' % expr % { job: 'job=~"node-exporter"' },
            customLables: k8sCustomLables,
            thresholds: thresholds,
          },
        },
        overallUtilizationRAM: {
          local expr = 'round((1 - sum by (job, nodename) (node_memory_MemAvailable_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) / sum by (job, nodename) (node_memory_MemTotal_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info))) * 100)',
          local thresholds = defaultTemplate.commonThresholds.node,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.memoryOverview],
          panel: {
            title: 'Overall Utilization',
            description: 'The percentage of the memory utilization is calculated by:\n```\n1 - (<memory available>/<memory total>)\n```',
            dataLinks: [
              { title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$.defaultConfig.grafanaDashboards.ids.memoryOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
              { title: 'K8s Overview', url: '/d/%s?%s' % [$.defaultConfig.grafanaDashboards.ids.memoryNamespaceOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
            ],
            expr: 'avg(%s)' % expr % { job: 'job=~"$job"' },
            thresholds: thresholds,
            gridPos: {
              x: 6,
              y: 17,
              w: 3,
            },
          },
          alert: {
            name: 'ClusterRAMOverallHigh',
            message: 'Cluster High RAM Overall Utilization {{ $value }}%',
            expr: 'avg(%s)' % expr % { job: 'job=~"node-exporter"' },
            customLables: k8sCustomLables,
            thresholds: thresholds,
          },
        },
        overallUtilizationDisk: {
          local expr = 'round((sum(node_filesystem_size_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) / ((sum(node_filesystem_size_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) + sum(node_filesystem_avail_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) * 100 > 0)',
          local thresholds = defaultTemplate.commonThresholds.node,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.diskOverview],
          panel: {
            title: 'Overall Utilization',
            description: 'The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition. See the list of explicitly ignored mount points and file systems [here](https://github.com/dNationCloud/kubernetes-monitoring-stack/blob/main/chart/values.yaml)',
            dataLinks: [{ title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$.defaultConfig.grafanaDashboards.ids.diskOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] }],
            expr: 'avg(%s)' % expr % { job: 'job=~"$job"' },
            thresholds: thresholds,
            gridPos: {
              x: 12,
              y: 17,
              w: 3,
            },
          },
          alert: {
            name: 'ClusterDiskOverallHigh',
            message: 'Cluster High Disk Overall Utilization {{ $value }}%',
            expr: 'avg(%s)' % expr % { job: 'job=~"node-exporter"' },
            customLables: k8sCustomLables,
            thresholds: thresholds,
          },
        },
        overallNetworkErrors: {
          local expr = 'sum(rate(node_network_transmit_errs_total{cluster=~"$cluster|", %(job)s, device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"} [5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename) + sum(rate(node_network_receive_errs_total{cluster=~"$cluster|", %(job)s, device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename)',
          local thresholds = {
            operator: '>=',
            warning: 10,
            critical: 15,
          },
          linkTo: [$.defaultConfig.grafanaDashboards.ids.networkOverview],
          panel: {
            title: 'Overall Errors',
            dataLinks: [
              { title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$.defaultConfig.grafanaDashboards.ids.networkOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
              { title: 'K8s Overview', url: '/d/%s?%s' % [$.defaultConfig.grafanaDashboards.ids.networkNamespaceOverview, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
            ],
            expr: 'sum(%s)' % expr % { job: 'job=~"$job"' },
            unit: 'pps',
            thresholds: thresholds,
            gridPos: {
              x: 18,
              y: 17,
              w: 3,
            },
          },
          alert: {
            name: 'ClusterNetworkOverallErrorsHigh',
            message: 'Cluster High Overall Network Errors Count {{ $value }}%',
            expr: 'sum(%s)' % expr % { job: 'job=~"node-exporter"' },
            customLables: k8sCustomLables,
            thresholds: thresholds,
          },
        },
        usedCores: {
          panel: {
            title: 'Used Cores',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'none',
            expr: '(1 - (avg(irate(node_cpu_seconds_total{cluster=~"$cluster", %(job)s, mode="idle"}[5m])))) * count(node_cpu_seconds_total{cluster=~"$cluster", %(job)s, mode="system"})' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 0,
              y: 20,
              w: 3,
              h: 2,
            },
          },
        },
        totalCores: {
          panel: {
            title: 'Total Cores',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'none',
            expr: 'count(node_cpu_seconds_total{cluster=~"$cluster", %(job)s, mode="system"})' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 3,
              y: 20,
              w: 3,
              h: 2,
            },
          },
        },
        usedRAM: {
          panel: {
            title: 'Used',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'bytes',
            expr: 'sum(node_memory_MemTotal_bytes{cluster=~"$cluster", %(job)s}) * (((1 - sum(node_memory_MemAvailable_bytes{cluster=~"$cluster", %(job)s}) / sum(node_memory_MemTotal_bytes{cluster=~"$cluster", %(job)s}))))' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 6,
              y: 20,
              w: 3,
              h: 2,
            },
          },
        },
        totalRAM: {
          panel: {
            title: 'Total',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'bytes',
            expr: 'sum(node_memory_MemTotal_bytes{cluster=~"$cluster", %(job)s})' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 9,
              y: 20,
              w: 3,
              h: 2,
            },
          },
        },
        usedDisk: {
          panel: {
            title: 'Used',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'bytes',
            expr: 'sum(node_filesystem_size_bytes{cluster=~"$cluster", %(job)s}) * ((\navg(\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", %(job)s}) by (device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", %(job)s}) by (device)) /\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", %(job)s}) by (device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", %(job)s}) by (device) +\nsum(node_filesystem_avail_bytes{cluster=~"$cluster", %(job)s}) by (device)) > 0\n)))' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 12,
              y: 20,
              w: 3,
              h: 2,
            },
          },
        },
        totalDisk: {
          panel: {
            title: 'Total',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'bytes',
            expr: 'sum(node_filesystem_size_bytes{cluster=~"$cluster", %(job)s})' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 15,
              y: 20,
              w: 3,
              h: 2,
            },
          },
        },
      },
      host: {
        local hostCustomLables = { alertgroup: $.defaultConfig.prometheusRules.alertGroupHost },

        targetDown: {
          panel: null,
          alert: {
            name: 'HostTargetDown',
            message: '{{ printf "%.4g" $value }}% of the {{ $labels.job }}/{{ $labels.service }} targets in {{ $labels.namespace }} namespace are down.',
            customLables: hostCustomLables,
            expr: '100 * (count by(job, namespace, service) (up{alertGroup="Host"} == 0) / count by(job, namespace, service) (up{alertGroup="Host"}))',
            thresholds: {
              operator: '>=',
              warning: 10,
              critical: 90,
            },
          },
        },
        overallUtilizationCPU: {
          local expr = 'round((1 - (avg(irate(node_cpu_seconds_total{cluster=~"$cluster|", %(job)s, mode="idle"}[5m]) * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename) )) * 100)',
          local thresholds = defaultTemplate.commonThresholds.node,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.nodeExporter],
          panel: {
            title: 'Overall Utilization',
            dataLinks: [{ title: 'System Overview', url: '/d/%s?var-job=$job&%s' % [$.defaultConfig.grafanaDashboards.ids.nodeExporter, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] }],
            expr: 'avg(%s)' % expr % { job: 'job=~"$job"' },
            thresholds: thresholds,
            gridPos: {
              x: 0,
              y: 6,
            },
          },
          alert: {
            name: 'HostCPUOverallHigh',
            message: 'Host {{ $labels.nodename }}: High CPU Overall Utilization {{ $value }}%',
            expr: expr % { job: 'job!~"node-exporter"' },
            linkGetParams: 'var-instance={{ $labels.nodename }}',
            customLables: hostCustomLables,
            thresholds: thresholds,
          },
        },
        overallUtilizationRAM: {
          local expr = 'round((1 - sum by (job, nodename) (node_memory_MemAvailable_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) / sum by (job, nodename) (node_memory_MemTotal_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info))) * 100)',
          local thresholds = defaultTemplate.commonThresholds.node,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.nodeExporter],
          panel: {
            title: 'Overall Utilization',
            description: 'The percentage of the memory utilization is calculated by:\n```\n1 - (<memory available>/<memory total>)\n```',
            dataLinks: [{ title: 'System Overview', url: '/d/%s?var-job=$job&%s' % [$.defaultConfig.grafanaDashboards.ids.nodeExporter, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] }],
            expr: 'avg(%s)' % expr % { job: 'job=~"$job"' },
            thresholds: thresholds,
            gridPos: {
              x: 6,
              y: 6,
            },
          },
          alert: {
            name: 'HostRAMOverallHigh',
            message: 'Host {{ $labels.nodename }}: High RAM Overall Utilization {{ $value }}%',
            expr: expr % { job: 'job!~"node-exporter"' },
            linkGetParams: 'var-instance={{ $labels.nodename }}',
            customLables: hostCustomLables,
            thresholds: thresholds,
          },
        },
        overallUtilizationDisk: {
          local expr = 'round((sum(node_filesystem_size_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) / ((sum(node_filesystem_size_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) + sum(node_filesystem_avail_bytes{cluster=~"$cluster|", %(job)s} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) * 100 > 0)',
          local thresholds = defaultTemplate.commonThresholds.node,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.nodeExporter],
          panel: {
            title: 'Overall Utilization',
            description: 'The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition. See the list of explicitly ignored mount points and file systems [here](https://github.com/dNationCloud/kubernetes-monitoring-stack/blob/main/chart/values.yaml)',
            dataLinks: [{ title: 'System Overview', url: '/d/%s?var-job=$job&%s' % [$.defaultConfig.grafanaDashboards.ids.nodeExporter, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] }],
            expr: 'max(%s)' % expr % { job: 'job=~"$job"' },
            thresholds: thresholds,
            gridPos: {
              x: 12,
              y: 6,
            },
          },
          alert: {
            name: 'HostDiskOverallHigh',
            message: 'Host {{ $labels.nodename }}: High Disk Overall Utilization {{ $value }}%',
            expr: expr % { job: 'job!~"node-exporter"' },
            linkGetParams: 'var-instance={{ $labels.nodename }}',
            customLables: hostCustomLables,
            thresholds: thresholds,
          },
        },
        overallNetworkErrors: {
          local expr = 'sum(rate(node_network_transmit_errs_total{cluster=~"$cluster|", %(job)s, device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"} [5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename) + sum(rate(node_network_receive_errs_total{cluster=~"$cluster|", %(job)s, device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename)',
          local thresholds = {
            operator: '>=',
            warning: 10,
            critical: 15,
          },
          linkTo: [$.defaultConfig.grafanaDashboards.ids.nodeExporter],
          panel: {
            title: 'Overall Errors',
            dataLinks: [{ title: 'System Overview', url: '/d/%s?var-job=$job&%s' % [$.defaultConfig.grafanaDashboards.ids.nodeExporter, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] }],
            expr: expr % { job: 'job=~"$job"' },
            unit: 'pps',
            thresholds: thresholds,
            gridPos: {
              x: 18,
              y: 6,
            },
          },
          alert: {
            name: 'HostNetworkOverallErrorsHigh',
            message: 'Host {{ $labels.nodename }}: High Overall Network Errors Count {{ $value }}%',
            expr: expr % { job: 'job!~"node-exporter"' },
            linkGetParams: 'var-instance={{ $labels.nodename }}',
            customLables: hostCustomLables,
            thresholds: thresholds,
          },
        },
        usedCores: {
          panel: {
            title: 'Used Cores',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'none',
            expr: '(1 - (avg(irate(node_cpu_seconds_total{cluster=~"$cluster", %(job)s, mode="idle"}[5m])))) * count(node_cpu_seconds_total{cluster=~"$cluster", %(job)s, mode="system"})' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 0,
              y: 9,
              w: 3,
              h: 2,
            },
          },
        },
        totalCores: {
          panel: {
            title: 'Total Cores',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'none',
            expr: 'count(node_cpu_seconds_total{cluster=~"$cluster", %(job)s, mode="system"})' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 3,
              y: 9,
              w: 3,
              h: 2,
            },
          },
        },
        usedRAM: {
          panel: {
            title: 'Used',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'bytes',
            expr: 'sum(node_memory_MemTotal_bytes{cluster=~"$cluster", %(job)s}) * (((1 - sum(node_memory_MemAvailable_bytes{cluster=~"$cluster", %(job)s}) / sum(node_memory_MemTotal_bytes{cluster=~"$cluster", %(job)s}))))' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 6,
              y: 9,
              w: 3,
              h: 2,
            },
          },
        },
        totalRAM: {
          panel: {
            title: 'Total',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'bytes',
            expr: 'sum(node_memory_MemTotal_bytes{cluster=~"$cluster", %(job)s})' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 9,
              y: 9,
              w: 3,
              h: 2,
            },
          },
        },
        usedDisk: {
          panel: {
            title: 'Used',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'bytes',
            expr: 'sum(node_filesystem_size_bytes{cluster=~"$cluster", %(job)s}) * ((max((sum(node_filesystem_size_bytes{cluster=~"$cluster", %(job)s}) by (device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", %(job)s}) by (device)) / (sum(node_filesystem_size_bytes{cluster=~"$cluster", %(job)s}) by (device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", %(job)s}) by (device) + sum(node_filesystem_avail_bytes{cluster=~"$cluster", %(job)s}) by (device)))))' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 12,
              y: 9,
              w: 3,
              h: 2,
            },
          },
        },
        totalDisk: {
          panel: {
            title: 'Total',
            colorMode: 'value',
            graphMode: 'none',
            unit: 'bytes',
            expr: 'sum(node_filesystem_size_bytes{cluster=~"$cluster", %(job)s})' % { job: 'job=~"$job"' },
            thresholds: { color: $.defaultConfig.grafanaDashboards.color.white, value: null },
            gridPos: {
              x: 15,
              y: 9,
              w: 3,
              h: 2,
            },
          },
        },
      },
      appTemplates:: {
        pythonFlask: {
          local expr = '(sum by (job) (rate(flask_http_request_duration_seconds_count{cluster=~"$cluster|", %(job)s,status!~"[4-5].*"}[5m])) / sum by (job) (rate(flask_http_request_duration_seconds_count{cluster=~"$cluster|", %(job)s}[5m])) * 100) > 0 OR (sum by (job) (rate(flask_http_request_duration_seconds_count{cluster=~"$cluster|", %(job)s}[5m])) + 100)',
          local thresholds = {
            operator: '<',
            critical: 85,
            warning: 95,
            lowest: 0,  // invalid range is always from minus infinity to 'lowest' thredhold
          },
          linkTo: [$.defaultConfig.grafanaDashboards.ids.pythonFlask],
          panel: {
            expr: '%s OR on() vector(-1)' % expr,
            thresholds: thresholds,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              w: 4,
            },
          },
          default: false,
          alert: {
            name: '%(prefix)sPythonFlaskSuccessRateLow',
            message: '%(prefix)s {{ $labels.job }}: Python Flask Success Rate (non-4|5xx responses) Low {{ $value }}%%',
            expr: expr % { job: 'job=~".+"' },
            linkGetParams: 'var-job={{ $labels.job }}',
            thresholds: thresholds,
          },
        },
        javaActuator: {
          local expr = '(sum by (job) (jvm_memory_used_bytes{cluster=~"$cluster|", %(job)s, area="heap"})*100/sum  by (job) (jvm_memory_max_bytes{cluster=~"$cluster|", %(job)s, area="nonheap"}) > sum  by (job) (jvm_memory_used_bytes{cluster=~"$cluster|", %(job)s, area="nonheap"})*100/sum  by (job) (jvm_memory_max_bytes{cluster=~"$cluster|", %(job)s, area="heap"}) or (sum  by (job) (jvm_memory_used_bytes{cluster=~"$cluster|", %(job)s, area="nonheap"})*100)/sum by (job) (jvm_memory_max_bytes{cluster=~"$cluster|", %(job)s, area="heap"}))',
          local thresholds = {
            operator: '>=',
            critical: 90,
            warning: 75,
            lowest: 0,  // invalid range is always from minus infinity to 'lowest' thredhold
          },
          linkTo: [$.defaultConfig.grafanaDashboards.ids.javaActuator],
          panel: {
            expr: '%s OR on() vector(-1)' % expr,
            thresholds: thresholds,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              w: 4,
            },
          },
          default: false,
          alert: {
            name: '%(prefix)sJavaActuatorHeapHigh',
            message: '%(prefix)s {{ $labels.job }}: Java Actuator Heap High {{ $value }}%%',
            expr: expr % { job: 'job=~".+"' },
            linkGetParams: 'var-job={{ $labels.job }}',
            thresholds: thresholds,
          },
        },
        nginxIngress: {
          local expr = '((sum by (job) (rate(nginx_ingress_controller_requests{cluster=~"$cluster|", %(job)s, status!~"[4-5].*"}[5m])) / sum by (job) (rate(nginx_ingress_controller_requests{cluster=~"$cluster|", %(job)s}[5m])) * 100) > 0 OR (sum by (job) (rate(nginx_ingress_controller_requests{cluster=~"$cluster|", %(job)s}[5m])) + 100))',
          local thresholds = {
            operator: '<',
            critical: 85,
            warning: 95,
            lowest: 0,  // invalid range is always from minus infinity to 'lowest' thredhold
          },
          default: false,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.nginxIngress],
          panel: {
            expr: '%s OR on() vector(-1)' % expr,
            thresholds: thresholds,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              w: 4,
            },
          },
          alert: {
            name: '%(prefix)sNginxIngressSuccessRateLow',
            message: '%(prefix)s {{ $labels.job }}: Nginx Ingress Success Rate (non-4|5xx responses) Low {{ printf "%%.0f" $value }}%%',
            expr: expr % { job: 'job=~".+"' },
            linkGetParams: 'var-job={{ $labels.job }}',
            thresholds: thresholds,
          },
        },
        nginxIngressCertificateExpiry: {
          local expr = 'bottomk(1, nginx_ingress_controller_ssl_expire_time_seconds{cluster=~"$cluster|", %(job)s} - time())',
          local minusInfinity = -$.defaultConfig.grafanaDashboards.constants.infinity,
          local invalid = minusInfinity - 1,
          local thresholds = {
            operator: '<',
            warning: 8 * 24 * 60 * 60,
            critical: 0,
            lowest: minusInfinity,  // invalid range is always from minus infinity to 'lowest' thredhold
          },
          default: false,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.nginxIngress],
          panel: {
            expr: '%s OR on() vector(%s)' % [expr, invalid],
            thresholds: thresholds,
            mappings: [{ text: '-', type: 1, value: invalid }],
            unit: 's',
            decimals: 0,
            dataLinks: [{ title: 'Detail', url: '/d/%s?var-job=%(job)s&%s' % [$.defaultConfig.grafanaDashboards.ids.nginxIngress, '%(job)s', $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] }],
            gridPos: {
              w: 4,
            },
          },
          alert: {
            name: '%(prefix)sNginxIngressCertificateExpiry',
            message: '%(prefix)s {{ $labels.job }}: Nginx Ingress Certificate Expiry in {{ printf "%%.2f" $value }} days',
            expr: '%s / 60 / 60 / 24' % (expr % { job: 'job=~".+"' }),
            linkGetParams: 'var-job={{ $labels.job }}',
            thresholds: thresholds {
              warning: thresholds.warning / 60 / 60 / 24,
              critical: thresholds.critical / 60 / 60 / 24,
            },
          },
        },
        nginxVts: {
          local expr = '(sum by (job) (rate(nginx_server_requests{cluster=~"$cluster|", %(job)s, code!~"[4-5].*", code!="total"}[5m])) / sum by (job) (rate(nginx_server_requests{cluster=~"$cluster|", %(job)s, code!="total"}[5m])) * 100) > 0 OR (sum by (job) (rate(nginx_server_requests{cluster=~"$cluster|", %(job)s}[5m])) + 100)',
          local thresholds = {
            operator: '<',
            critical: 85,
            warning: 95,
            lowest: 0,  // invalid range is always from minus infinity to 'lowest' thredhold
          },
          default: false,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.nginxVts],
          panel: {
            expr: '%s OR on() vector(-1)' % expr,
            thresholds: thresholds,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              w: 4,
            },
          },
          alert: {
            name: '%(prefix)sNginxVTSSuccessRateLow',
            message: '%(prefix)s {{ $labels.job }}: Nginx VTS Success Rate (non-4|5xx responses) Low {{ $value }}%%',
            expr: expr % { job: 'job=~".+"' },
            linkGetParams: 'var-job={{ $labels.job }}',
            thresholds: thresholds,
          },
        },
        autoscaler: {
          local expr = '(sum by (job) (autoscaler_healthy{cluster=~"$cluster|", %(job)s}) / sum by (job) (autoscaler_instances{cluster=~"$cluster|", %(job)s}) * 100)',
          local thresholds = {
            operator: '<',
            critical: 85,
            warning: 95,
            lowest: 0,  // invalid range is always from minus infinity to 'lowest' thredhold
          },
          default: false,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.autoscaler],
          panel: {
            expr: '%s OR on() vector(-1)' % expr,
            thresholds: thresholds,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              w: 4,
            },
          },
          alert: {
            name: '%(prefix)sAutoscalerHealthLow',
            message: '%(prefix)s {{ $labels.job }}: Autoscaler Health Low {{ $value }}%%',
            expr: expr % { job: 'job=~".+"' },
            linkGetParams: 'var-job={{ $labels.job }}',
            thresholds: thresholds,
          },
        },
        postfix: {
          local expr = '(sum by (job) (postfix_size{cluster=~"$cluster|", %(job)s}))',
          local thresholds = {
            operator: '>=',
            warning: 5,
            critical: 10,
            lowest: 0,  // invalid range is always from minus infinity to 'lowest' thredhold
          },
          default: false,
          linkTo: [$.defaultConfig.grafanaDashboards.ids.postfix],
          panel: {
            expr: '%s OR on() vector(-1)' % expr,
            thresholds: thresholds,
            mappings: [{ text: '-', type: 1, value: -1 }],
            unit: 'mailq',
            gridPos: {
              w: 4,
            },
          },
          alert: {
            name: '%(prefix)sPostfixQueueSizeHigh',
            message: '%(prefix)s {{ $labels.job }}: Postfix Queue Size High {{ $value }}%%',
            expr: expr % { job: 'job=~".+"' },
            linkGetParams: 'var-job={{ $labels.job }}',
            thresholds: thresholds,
            mappings: [{ text: '-', type: 1, value: -1 }],
          },
        },
        apache: {
          default: false,
          panel: {
            expr: '(sum(up{%(job)s}) / count(up{cluster=~"$cluster|", %(job)s}))*100 OR on() vector(-1)',
            thresholds: defaultTemplate.commonThresholds.app { lowest: 0 },  // invalid range is always from minus infinity to 'lowest' thredhold,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              w: 4,
            },
          },
        },
        cAdvisor: {
          default: false,
          panel: {
            expr: '(sum(up{%(job)s}) / count(up{cluster=~"$cluster|", %(job)s}))*100 OR on() vector(-1)',
            thresholds: defaultTemplate.commonThresholds.app { lowest: 0 },  // invalid range is always from minus infinity to 'lowest' thredhold,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              w: 4,
            },
          },
        },
        phpFpm: {
          default: false,
          panel: {
            expr: '(sum(up{%(job)s}) / count(up{cluster=~"$cluster|", %(job)s}))*100 OR on() vector(-1)',
            thresholds: defaultTemplate.commonThresholds.app { lowest: 0 },  // invalid range is always from minus infinity to 'lowest' thredhold,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              w: 4,
            },
          },
        },
        rabbitmq: {
          default: false,
          panel: {
            expr: '(sum(up{%(job)s}) / count(up{cluster=~"$cluster|", %(job)s}))*100 OR on() vector(-1)',
            thresholds: defaultTemplate.commonThresholds.app { lowest: 0 },  // invalid range is always from minus infinity to 'lowest' thredhold,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              w: 4,
            },
          },
        },
        nginxNrpe: {
          default: false,
          panel: {
            expr: '(sum(up{%(job)s}) / count(up{cluster=~"$cluster|", %(job)s}))*100 OR on() vector(-1)',
            thresholds: defaultTemplate.commonThresholds.app { lowest: 0 },  // invalid range is always from minus infinity to 'lowest' thredhold,
            mappings: [{ text: '-', type: 1, value: -1 }],
            gridPos: {
              w: 4,
            },
          },
        },
        genericApp: {
          default: false,
          panel: {
            description: 'GenericApp template. Used when application monitoring is requested but appropriate template was not found.',
            expr: '(sum(up{%(job)s}) / count(up{cluster=~"$cluster|", %(job)s}))*100',
            thresholds: defaultTemplate.commonThresholds.app,
            gridPos: {
              w: 4,
            },
          },
        },
      },
      k8sApps: defaultTemplate.getTemplatesApp($.defaultConfig.prometheusRules.alertGroupClusterApp, self.appTemplates),
      hostApps: defaultTemplate.getTemplatesApp($.defaultConfig.prometheusRules.alertGroupHostApp, self.appTemplates),
    },
    L0: {
      local maxWarnings = $.defaultConfig.grafanaDashboards.constants.maxWarnings,
      k8s: {
        main: {
          local expr = 'sum(ALERTS{alertname!="Watchdog", cluster=~"%(cluster)s", alertstate="firing", severity="warning", alertgroup=~"%(groupCluster)s|%(groupApp)s"} OR on() vector(0)) + sum(ALERTS{alertname!="Watchdog", cluster=~"%(cluster)s", alertstate="firing", severity="critical", alertgroup=~"%(groupCluster)s|%(groupApp)s"} OR on() vector(0)) * %(maxWarnings)d',
          local thresholds = {
            operator: '>=',
            warning: 1,
            critical: maxWarnings,
          },
          panel: {
            expr: expr,
            thresholds: thresholds,
            graphMode: 'none',
            unit: 'none',
            mappings: [
              { from: 0, text: 'OK', to: 0, type: 2, value: '' },
              { from: 1, text: 'Warning', to: maxWarnings - 1, type: 2, value: '' },
              { from: maxWarnings, text: 'Critical', to: $.defaultConfig.grafanaDashboards.constants.infinity, type: 2, value: '' },
            ],
            gridPos: {
              w: 4,
              h: 3,
            },
          },
        },
      },
      host: {
        main: {
          local expr = 'sum(ALERTS{alertname!="Watchdog", alertstate="firing", severity="warning", job=~"%(job)s", alertgroup=~"%(groupHost)s|%(groupHostApp)s"} OR on() vector(0)) + sum(ALERTS{alertname!="Watchdog", alertstate="firing", severity="critical", job=~"%(job)s", alertgroup=~"%(groupHost)s|%(groupHostApp)s"} OR on() vector(0)) * %(maxWarnings)d',
          local thresholds = {
            operator: '>=',
            warning: 1,
            critical: maxWarnings,
          },
          panel: {
            expr: expr,
            thresholds: thresholds,
            graphMode: 'none',
            unit: 'none',
            mappings: [
              { from: 0, text: 'OK', to: 0, type: 2, value: '' },
              { from: 1, text: 'Warning', to: maxWarnings - 1, type: 2, value: '' },
              { from: maxWarnings, text: 'Critical', to: $.defaultConfig.grafanaDashboards.constants.infinity, type: 2, value: '' },
            ],
            gridPos: {
              w: 4,
              h: 3,
            },
          },
        },
      },
    },
    L2: {
      pvcOverview: {
        pvcOverviewTable: {
          base: 'baseTableTemplate',
          panel: {
            local colors = [$.defaultConfig.grafanaDashboards.color.green, $.defaultConfig.grafanaDashboards.color.orange, $.defaultConfig.grafanaDashboards.color.red],
            local valueMaps = [
              { text: 'Bound', value: 1 },
              { text: 'Lost', value: 2 },
              { text: 'Pending', value: 3 },
            ],
            title: 'Persistent Volumes',
            description: 'Capacity is available only for remote pvc.',
            sort: { col: 3, desc: true },
            styles: [
              { pattern: 'Time', type: 'hidden' },
              { alias: 'Capacity', pattern: 'Value #A', colors: colors, colorMode: 'cell', type: 'number', unit: 'percent', thresholds: [30, 40] },
              { alias: 'Status', pattern: 'Value #B', colors: colors, colorMode: 'cell', type: 'string', thresholds: [2, 2], valueMaps: valueMaps, mappingType: 1 },
              { alias: 'PVC', pattern: 'persistentvolumeclaim', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-namespace=${__cell_1}&var-volume=${__cell_2}&%s' % [$.defaultConfig.grafanaDashboards.ids.persistentVolumes, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
              { alias: 'Namespace', pattern: 'namespace', type: 'string' },
            ],
            expr: [
              'sum by (persistentvolumeclaim, namespace) (((kubelet_volume_stats_capacity_bytes{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"} - kubelet_volume_stats_available_bytes{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"}) / kubelet_volume_stats_capacity_bytes{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"}) * 100)',
              |||
                sum by (persistentvolumeclaim, namespace) (kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc", phase="Bound"} * 1) +
                sum by (persistentvolumeclaim, namespace) (kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc", phase="Lost"} * 2) +
                sum by (persistentvolumeclaim, namespace) (kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc", phase="Pending"} * 3)
              |||,
            ],
          },
        },
      },
      nodeOverview: {
        nodeOverviewTable: {
          base: 'baseTableTemplate',
          panel: {
            local colors = [$.defaultConfig.grafanaDashboards.color.green, $.defaultConfig.grafanaDashboards.color.orange, $.defaultConfig.grafanaDashboards.color.red],
            local valueMaps = [
              { text: 'Failed', value: 1 },
              { text: 'OK', value: 0 },
            ],
            local thresholds = [1, 1],
            title: 'Nodes',
            sort: { col: 6, desc: true },
            styles: [
              { pattern: 'Time', type: 'hidden' },
              { alias: 'Schedulable', pattern: 'Value #A', colors: colors, colorMode: 'cell', type: 'string', thresholds: thresholds, valueMaps: valueMaps, mappingType: 1 },
              { alias: 'Disk Pressure', pattern: 'Value #B', colors: colors, colorMode: 'cell', type: 'string', thresholds: thresholds, valueMaps: valueMaps, mappingType: 1 },
              { alias: 'Memory Pressure', pattern: 'Value #C', colors: colors, colorMode: 'cell', type: 'string', thresholds: thresholds, valueMaps: valueMaps, mappingType: 1 },
              { alias: 'PID Pressure', pattern: 'Value #D', colors: colors, colorMode: 'cell', type: 'string', thresholds: thresholds, valueMaps: valueMaps, mappingType: 1 },
              { alias: 'Ready', pattern: 'Value #E', colors: colors, colorMode: 'cell', type: 'string', thresholds: thresholds, valueMaps: valueMaps, mappingType: 1 },
              { alias: 'Node', pattern: 'node', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-view=pod&var-instance=$__cell&%s' % [$.defaultConfig.grafanaDashboards.ids.containerDetail, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
            ],
            expr: [
              'sum by (node) (kube_node_spec_unschedulable{cluster=~"$cluster"})',
              'sum by (node) (kube_node_status_condition{cluster=~"$cluster", condition="DiskPressure", status=~"true|unknown"})',
              'sum by (node) (kube_node_status_condition{cluster=~"$cluster", condition="MemoryPressure", status=~"true|unknown"})',
              'sum by (node) (kube_node_status_condition{cluster=~"$cluster", condition="PIDPressure", status=~"true|unknown"})',
            ],
          },
        },
      },
      statefulSetOverview: {
        statefulSetOverviewTable: {
          base: 'baseTableTemplate',
          panel: {
            local colors = [$.defaultConfig.grafanaDashboards.color.green, $.defaultConfig.grafanaDashboards.color.orange, $.defaultConfig.grafanaDashboards.color.red],
            local thresholds = [1, 1],
            local rangeMaps = [
              { from: 0, text: 'OK', to: 0 },
              { from: 1, text: 'Failed', to: $.defaultConfig.grafanaDashboards.constants.infinity },
            ],
            title: 'StatefulSets',
            sort: { col: 4, desc: true },
            styles: [
              { pattern: 'Time', type: 'hidden' },
              { alias: 'Updated', pattern: 'Value #A', type: 'number' },
              { alias: 'Ready', pattern: 'Value #B', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
              { alias: 'StatefulSet', pattern: 'statefulset', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-namespace=${__cell_1}&var-statefulset=${__cell_2}&%s' % [$.defaultConfig.grafanaDashboards.ids.statefulSet, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
              { alias: 'Namespace', pattern: 'namespace', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-namespace=$__cell&var-pod=All&var-view=pod&var-search=&%s' % [$.defaultConfig.grafanaDashboards.ids.containerDetail, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
            ],
            expr: [
              'sum by (statefulset, namespace) (kube_statefulset_status_replicas_updated{cluster=~"$cluster", namespace=~"$namespace", statefulset=~"$statefulset"})',
              'sum by (statefulset, namespace) (kube_statefulset_status_replicas{cluster=~"$cluster", namespace=~"$namespace", statefulset=~"$statefulset"}) - sum by (statefulset, namespace) (kube_statefulset_status_replicas_ready{cluster=~"$cluster", namespace=~"$namespace", statefulset=~"$statefulset"})',
            ],
          },
        },
      },
      podOverview: {
        podOverviewTable: {
          base: 'baseTableTemplate',
          panel: {
            local colors = [$.defaultConfig.grafanaDashboards.color.green, $.defaultConfig.grafanaDashboards.color.orange, $.defaultConfig.grafanaDashboards.color.red],
            local valueMaps = [
              { text: 'Running', value: 1 },
              { text: 'Succeeded', value: 2 },
              { text: 'Unknown', value: 3 },
              { text: 'Failed', value: 4 },
              { text: 'Pending', value: 5 },
            ],
            title: 'Pods',
            sort: { col: 3, desc: true },
            styles: [
              { pattern: 'Time', type: 'hidden' },
              { alias: 'Status', pattern: 'Value', type: 'string', mappingType: 1, valueMaps: valueMaps, thresholds: [3, 3], colorMode: 'cell', colors: colors },
              { alias: 'Namespace', pattern: 'namespace', type: 'string' },
              { alias: 'Pod', pattern: 'pod', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-container=All&var-view=pod&var-namespace=${__cell_1}&var-pod=${__cell_2}&var-search=&%s' % [$.defaultConfig.grafanaDashboards.ids.containerDetail, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
            ],
            expr: [
              |||
                sum by (namespace, pod) (kube_pod_status_phase{cluster=~"$cluster", namespace=~"$namespace", phase="Running"} * 1) +
                sum by (namespace, pod) (kube_pod_status_phase{cluster=~"$cluster", namespace=~"$namespace", phase="Succeeded"} * 2) +
                sum by (namespace, pod) (kube_pod_status_phase{cluster=~"$cluster", namespace=~"$namespace", phase="Unknown"} * 3) +
                sum by (namespace, pod) (kube_pod_status_phase{cluster=~"$cluster", namespace=~"$namespace", phase="Failed"} * 4) +
                sum by (namespace, pod) (kube_pod_status_phase{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", phase="Pending"} * 5)
              |||,
            ],
          },
        },
      },
      deploymentOverview: {
        deploymentOverviewTable: {
          base: 'baseTableTemplate',
          panel: {
            local colors = [$.defaultConfig.grafanaDashboards.color.green, $.defaultConfig.grafanaDashboards.color.orange, $.defaultConfig.grafanaDashboards.color.red],
            local rangeMaps = [
              { from: 0, text: 'OK', to: 0 },
              { from: 1, text: 'Failed', to: $.defaultConfig.grafanaDashboards.constants.infinity },
            ],
            local thresholds = [1, 1],
            title: 'Deployments',
            sort: { col: 4, desc: true },
            styles: [
              { pattern: 'Time', type: 'hidden' },
              { alias: 'Updated', pattern: 'Value #A', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
              { alias: 'Available', pattern: 'Value #B', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
              { alias: 'Deployment', pattern: 'deployment', type: 'string' },
              { alias: 'Namespace', pattern: 'namespace', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-namespace=$__cell&var-pod=All&var-view=pod&var-search=&%s' % [$.defaultConfig.grafanaDashboards.ids.containerDetail, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
            ],
            expr: [
              'sum by (deployment, namespace) (kube_deployment_status_replicas{cluster=~"$cluster", namespace=~"$namespace", deployment=~"$deployment"}) - sum by (deployment, namespace) (kube_deployment_status_replicas_updated{cluster=~"$cluster", namespace=~"$namespace", deployment=~"$deployment"})',
              'sum by (deployment, namespace) (kube_deployment_status_replicas{cluster=~"$cluster", namespace=~"$namespace", deployment=~"$deployment"}) - sum by (deployment, namespace) (kube_deployment_status_replicas_available{cluster=~"$cluster", namespace=~"$namespace", deployment=~"$deployment"})',
            ],
          },
        },
      },
      daemonSetOverview: {
        daemonSetOverviewTable: {
          base: 'baseTableTemplate',
          panel: {
            local colors = [$.defaultConfig.grafanaDashboards.color.green, $.defaultConfig.grafanaDashboards.color.orange, $.defaultConfig.grafanaDashboards.color.red],
            local rangeMaps = [
              { from: 0, text: 'OK', to: 0 },
              { from: 1, text: 'Failed', to: $.defaultConfig.grafanaDashboards.constants.infinity },
            ],
            local thresholds = [1, 1],
            title: 'DaemonSets',
            sort: { col: 6, desc: true },
            styles: [
              { pattern: 'Time', type: 'hidden' },
              { alias: 'Scheduled', pattern: 'Value #A', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
              { alias: 'Updated', pattern: 'Value #B', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
              { alias: 'Available', pattern: 'Value #C', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
              { alias: 'Ready', pattern: 'Value #D', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
              { alias: 'DaemonSet', pattern: 'daemonset', type: 'string' },
              { alias: 'Namespace', pattern: 'namespace', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-namespace=$__cell&var-pod=All&var-view=pod&var-search=&%s' % [$.defaultConfig.grafanaDashboards.ids.containerDetail, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
            ],
            expr: [
              'sum by (daemonset, namespace) (kube_daemonset_status_number_misscheduled{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"})',
              'sum by (daemonset, namespace) (kube_daemonset_status_desired_number_scheduled{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"}) - sum by (daemonset, namespace) (kube_daemonset_updated_number_scheduled{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"})',
              'sum by (daemonset, namespace) (kube_daemonset_status_desired_number_scheduled{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"}) - sum by (daemonset, namespace) (kube_daemonset_status_number_available{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"})',
              'sum by (daemonset, namespace) (kube_daemonset_status_desired_number_scheduled{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"}) - sum by (daemonset, namespace) (kube_daemonset_status_number_ready{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"})',
            ],
          },
        },
      },
      containerOverview: {
        containerOverviewTable: {
          base: 'baseTableTemplate',
          panel: {
            local colors = [$.defaultConfig.grafanaDashboards.color.green, $.defaultConfig.grafanaDashboards.color.orange, $.defaultConfig.grafanaDashboards.color.red],
            local waitingErrors = ['CrashLoopBackOff', 'CreateContainerConfigError', 'ErrImagePull', 'ImagePullBackOff', 'CreateContainerError', 'InvalidImageName', 'CrashLoopBackOff'],
            local terminatedErrors = ['OOMKilled', 'Error', 'ContainerCannotRun', 'DeadlineExceeded', 'Evicted'],

            local valueMapsOk = [
              { text: 'Terminated (Completed)', value: 1 },
              { text: 'Running', value: 2 },
              { text: 'Waiting (ContainerCreating)', value: 3 },
            ],
            local writingErrorsValues = [{ err: waitingErrors[i], value: utils.getNextIndex([valueMapsOk]) + i } for i in std.range(0, std.length(waitingErrors) - 1)],
            local terminatedErrorsValues = [{ err: terminatedErrors[i], value: utils.getNextIndex([valueMapsOk, writingErrorsValues]) + i } for i in std.range(0, std.length(terminatedErrors) - 1)],

            local valueMapsWaitingErrors = [{ text: 'Waiting (%s)' % map.err, value: map.value } for map in writingErrorsValues],
            local valueMapsTerminatedErrors = [{ text: 'Terminated (%s)' % map.err, value: map.value } for map in terminatedErrorsValues],
            local valueMaps = std.flattenArrays([valueMapsOk, valueMapsWaitingErrors, valueMapsTerminatedErrors]),

            local okQueries = [
              'sum by (container, namespace, pod) (kube_pod_container_status_terminated_reason{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container", reason="Completed"} * 1)',
              'sum by (container, namespace, pod) (kube_pod_container_status_running{cluster=~"$cluster"} * 2)',
              'sum by (container, namespace, pod) (kube_pod_container_status_waiting_reason{cluster=~"$cluster", reason="ContainerCreating"} * 3)',
            ],

            local waitingErrorsQueries = ['sum by (container, namespace, pod) (kube_pod_container_status_waiting_reason{cluster=~"$cluster", reason="%(err)s"} * %(value)d)' % map for map in writingErrorsValues],
            local terminatedErrorsQueries = ['sum by (container, namespace, pod) (kube_pod_container_status_terminated_reason{cluster=~"$cluster", reason="%(err)s"} * %(value)d)' % map for map in terminatedErrorsValues],
            local statusExpr = std.join(' + \n', std.flattenArrays([okQueries, waitingErrorsQueries, terminatedErrorsQueries])),

            title: 'Containers',
            sort: { col: 6, desc: true },
            styles: [
              { pattern: 'Time', type: 'hidden' },
              { alias: 'Status', pattern: 'Value #A', type: 'string', mappingType: 1, valueMaps: valueMaps, thresholds: [4, 4], colorMode: 'cell', colors: colors },
              { alias: 'Restarts', pattern: 'Value #B', type: 'number', thresholds: [5, 10], colorMode: 'cell', colors: colors },
              { alias: 'Container', pattern: 'container', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-container=${__cell_1}&var-namespace=${__cell_2}&var-pod=${__cell_3}&var-view=container&var-search=&%s' % [$.defaultConfig.grafanaDashboards.ids.containerDetail, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
              { alias: 'Namespace', pattern: 'namespace', type: 'string' },
              { alias: 'Pod', pattern: 'pod', type: 'string' },
            ],
            expr: [
              statusExpr,
              'sum by (container, namespace, pod) (kube_pod_container_status_restarts_total{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"})',
            ],
          },
        },
      },
      jobOverview: {
        jobOverviewTable: {
          base: 'baseTableTemplate',
          panel: {
            local colors = [$.defaultConfig.grafanaDashboards.color.green, $.defaultConfig.grafanaDashboards.color.orange, $.defaultConfig.grafanaDashboards.color.red],
            local valueMaps = [
              { text: 'Succeeded', value: 1 },
              { text: 'Active', value: 2 },
              { text: 'Failed', value: 3 },
            ],
            title: 'Jobs',
            sort: { col: 4, desc: true },
            styles: [
              { pattern: 'Time', type: 'hidden' },
              { alias: 'Status', pattern: 'Value', colors: colors, colorMode: 'cell', type: 'string', thresholds: [3, 3], valueMaps: valueMaps, mappingType: 1 },
              { alias: 'Job name', pattern: 'job_name', type: 'string' },
              { alias: 'Owner', pattern: 'owner_name', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-container=${__cell_3}&var-namespace=${__cell_2}&var-view=container&var-search=&%s' % [$.defaultConfig.grafanaDashboards.ids.containerDetail, $.defaultConfig.grafanaDashboards.dataLinkCommonArgs] },
              { alias: 'Namespace', pattern: 'namespace', type: 'string' },
            ],
            expr: [
              |||
                sum by (job_name, namespace) (kube_job_status_succeeded{cluster=~"$cluster", namespace=~"$namespace", job=~"$job"} * 1) * on(job_name, namespace) group_left(owner_name) kube_job_owner{cluster=~"$cluster", namespace=~"$namespace", job_name=~"$job_name"} +
                sum by (job_name, namespace) (kube_job_status_active{cluster=~"$cluster", namespace=~"$namespace", job=~"$job"} * 2) * on(job_name, namespace) group_left(owner_name) kube_job_owner{cluster=~"$cluster", namespace=~"$namespace", job_name=~"$job_name"} +
                sum by (job_name, namespace) (kube_job_status_failed{cluster=~"$cluster", namespace=~"$namespace", job=~"$job"} * 3) * on(job_name, namespace) group_left(owner_name) kube_job_owner{cluster=~"$cluster", namespace=~"$namespace", job_name=~"$job_name"}
              |||,
            ],
          },
        },
      },
    },
  },
}
