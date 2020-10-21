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
      groups: [
        $.newRuleGroup('k8s.rules')
        .addAlertPair(
          name='NodesHealthLow',
          message='"{{ $labels.node }}": Node Health Low {{ $value }}%',
          expr='round(sum(kube_node_info) by (job, node) / (sum(kube_node_info) by (job, node) + sum(kube_node_spec_unschedulable)  by (job, node) + sum(kube_node_status_condition{condition="DiskPressure",status="true"}) by (job, node) + sum(kube_node_status_condition{condition="MemoryPressure",status="true"}) by (job, node) ) * 100)',
          thresholds=$._config.thresholds.k8s,
        )
        .addAlertPair(
          name='RunningPodsHealthLow',
          message='Pods Health Low {{ $value }}%',
          expr='round(sum(kube_pod_status_phase{phase="Running"}) / (sum(kube_pod_status_phase{phase="Running"}) + sum(kube_pod_status_phase{phase="Pending"}) + sum(kube_pod_status_phase{phase="Failed"}) + sum(kube_pod_status_phase{phase="Unknown"})) * 100)',
          thresholds=$._config.thresholds.k8s,
        )
        .addAlertPair(
          name='RunningStatefulSetsHealthLow',
          message='StatefulSets Health Low {{ $value }}%',
          expr='round(sum(kube_statefulset_status_replicas_current{job="kube-state-metrics"}) / sum(kube_statefulset_status_replicas{job="kube-state-metrics"}) * 100)',
          thresholds=$._config.thresholds.k8s,
        )
        .addAlertPair(
          name='PVCBoundRateLow',
          message='PVC Bound Rate Low {{ $value }}%',
          expr='round(sum(kube_persistentvolumeclaim_status_phase{phase="Bound"}) / (sum(kube_persistentvolumeclaim_status_phase{phase="Bound"}) + sum(kube_persistentvolumeclaim_status_phase{phase="Pending"}) + sum(kube_persistentvolumeclaim_status_phase{phase="Lost"})) * 100)',
          thresholds=$._config.thresholds.k8s,
        )
        .addAlertPair(
          name='RunningDeploymentsHealthLow',
          message='Running Deployments Health Low {{ $value }}%',
          expr='round(sum(kube_deployment_status_replicas_updated) / (sum(kube_deployment_status_replicas) + sum(kube_deployment_status_replicas_unavailable)) * 100)',
          thresholds=$._config.thresholds.k8s,
        )
        .addAlertPair(
          name='RunningContainersHealthLow',
          message='Running Containers Health Low {{ $value }}%',
          expr='round(sum(kube_pod_container_status_running) / (sum(kube_pod_container_status_running) +  sum(kube_pod_container_status_terminated_reason{reason!="Completed"}) + sum(kube_pod_container_status_waiting)) * 100)',
          thresholds=$._config.thresholds.k8s,
        )
        .addAlertPair(
          name='SucceededJobsRateLow',
          message='Succeeded Jobs Rate Low {{ $value }}%',
          expr='round(sum(kube_job_status_succeeded) / (sum(kube_job_status_succeeded) + sum(kube_job_status_failed)) * 100)',
          thresholds=$._config.thresholds.k8s,
        ),
      ],
    },
  },
}
