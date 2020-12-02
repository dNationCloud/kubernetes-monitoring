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

/* K8s prometheus rules */

{
  prometheusRules+:: {
    'k8s.rules': {
      local k8sRules =
        $.newAlertPair(
          name='NodesHealthLow',
          message='"{{ $labels.node }}": Node Health Low {{ $value }}%',
          expr=$._config.templates.nodeHealth.expr,
          thresholds=$._config.templates.nodeHealth.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='RunningPodsHealthLow',
          message='Pods Health Low {{ $value }}%',
          expr=$._config.templates.runningPods.expr,
          thresholds=$._config.templates.runningPods.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='RunningStatefulSetsHealthLow',
          message='StatefulSets Health Low {{ $value }}%',
          expr=$._config.templates.runningStatefulSets.expr,
          thresholds=$._config.templates.runningStatefulSets.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='RunningDaemonSetsHealthLow',
          message='DaemonSets Health Low {{ $value }}%',
          expr=$._config.templates.daemonSetsHealth.expr,
          thresholds=$._config.templates.daemonSetsHealth.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='PVCBoundRateLow',
          message='PVC Bound Rate Low {{ $value }}%',
          expr=$._config.templates.pvcBound.expr,
          thresholds=$._config.templates.pvcBound.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='RunningDeploymentsHealthLow',
          message='Running Deployments Health Low {{ $value }}%',
          expr=$._config.templates.deploymentsHealth.expr,
          thresholds=$._config.templates.deploymentsHealth.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='RunningContainersHealthLow',
          message='Running Containers Health Low {{ $value }}%',
          expr=$._config.templates.runningContainers.expr,
          thresholds=$._config.templates.runningContainers.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='SucceededJobsRateLow',
          message='Succeeded Jobs Rate Low {{ $value }}%',
          expr=$._config.templates.succeededJobs.expr,
          thresholds=$._config.templates.succeededJobs.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='ClusterApiServerHealthLow',
          message='Cluster Api Server Health Low {{ $value }}%',
          expr=$._config.templates.apiServerHealth.expr,
          thresholds=$._config.templates.apiServerHealth.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='ClusterControllerManagerHealthLow',
          message='Cluster Controller Manager Health Low {{ $value }}%',
          expr=$._config.templates.controllerManagerHealth.expr,
          thresholds=$._config.templates.controllerManagerHealth.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='ClusterEtcdHealthLow',
          message='Cluster Etcd Health Low {{ $value }}%',
          expr=$._config.templates.etcdHealth.expr,
          thresholds=$._config.templates.etcdHealth.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='ClusterKubeletHealthLow',
          message='Cluster Kubelet Health Low {{ $value }}%',
          expr=$._config.templates.kubeletHealth.expr,
          thresholds=$._config.templates.kubeletHealth.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='ClusterProxyHealthLow',
          message='Cluster Proxy Health Low {{ $value }}%',
          expr=$._config.templates.proxyHealth.expr,
          thresholds=$._config.templates.proxyHealth.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ) +
        $.newAlertPair(
          name='ClusterSchedulerHealthLow',
          message='Cluster Scheduler Health Low {{ $value }}%',
          expr=$._config.templates.schedulerHealth.expr,
          thresholds=$._config.templates.schedulerHealth.thresholds,
          customLables={ alertgroup: $._config.prometheusRules.alertGroupCluster },
        ),
      groups: [
        $.newRuleGroup('k8s.rules')
        .addRules(k8sRules),
      ],
    },
  },
}
