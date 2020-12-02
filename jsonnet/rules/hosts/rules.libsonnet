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
    'hosts.rules': {
      local clusterRules(alertgroup, job) =
        $.newAlertPair(
          name='%sCPUOverallHigh' % alertgroup,
          message='%s High CPU Overall Utilization {{ $value }}%s' % [alertgroup, '%'],
          expr='avg(%s)' % $._config.templates.nodeCpuUtilization.expr % { job: job },
          thresholds=$._config.templates.nodeCpuUtilization.thresholds,
          customLables={ alertgroup: alertgroup },
        ) +
        $.newAlertPair(
          name='%sRAMOverallHigh' % alertgroup,
          message='%s High RAM Overall Utilization {{ $value }}%s' % [alertgroup, '%'],
          expr='avg(%s)' % $._config.templates.nodeRamUtilization.expr % { job: job },
          thresholds=$._config.templates.nodeRamUtilization.thresholds,
          customLables={ alertgroup: alertgroup },
        ) +
        $.newAlertPair(
          name='%sDiskOverallHigh' % alertgroup,
          message='%s High Disk Overall Utilization {{ $value }}%s' % [alertgroup, '%'],
          expr='avg(%s)' % $._config.templates.nodeDiskUtilization.expr % { job: job },
          thresholds=$._config.templates.nodeDiskUtilization.thresholds,
          customLables={ alertgroup: alertgroup },
        ) +
        $.newAlertPair(
          name='%sNetworkOverallErrorsHigh' % alertgroup,
          message='%s High Overall Network Errors Count {{ $value }}%s' % [alertgroup, '%'],
          expr='sum(%s)' % $._config.templates.nodeNetworkErrors.expr % { job: job },
          thresholds=$._config.templates.nodeNetworkErrors.thresholds,
          customLables={ alertgroup: alertgroup },
        ),
      local hostRules(alertgroup, job) =
        $.newAlertPair(
          name='%sCPUUtilizationHigh' % alertgroup,
          message='%s {{ $labels.nodename }}: High CPU Utilization {{ $value }}%s' % [alertgroup, '%'],
          expr=$._config.templates.nodeCpuUtilization.expr % { job: job },
          thresholds=$._config.templates.nodeCpuUtilization.thresholds,
          customLables={ alertgroup: alertgroup },
        ) +
        $.newAlertPair(
          name='%sRAMUtilizationHigh' % alertgroup,
          message='%s {{ $labels.nodename }}: High RAM Utilization {{ $value }}%s' % [alertgroup, '%'],
          expr=$._config.templates.nodeRamUtilization.expr % { job: job },
          thresholds=$._config.templates.nodeRamUtilization.thresholds,
          customLables={ alertgroup: alertgroup },
        ) +
        $.newAlertPair(
          name='%sDiskUtilizationHigh' % alertgroup,
          message='%s {{ $labels.nodename }}: High Disk Utilization {{ $value }}%s' % [alertgroup, '%'],
          expr=$._config.templates.nodeDiskUtilization.expr % { job: job },
          thresholds=$._config.templates.nodeDiskUtilization.thresholds,
          customLables={ alertgroup: alertgroup },
        ) +
        $.newAlertPair(
          name='%sNetworkErrorsHigh' % alertgroup,
          message='%s {{ $labels.nodename }}: High Network Errors Count {{ $value }}%s' % [alertgroup, '%'],
          expr=$._config.templates.nodeNetworkErrors.expr % { job: job },
          thresholds=$._config.templates.nodeNetworkErrors.thresholds,
          customLables={ alertgroup: alertgroup },
        ),

      groups: [
        $.newRuleGroup('hosts.rules')
        .addRules(
          // Add overall k8s cluster rules
          clusterRules($._config.prometheusRules.alertGroupCluster, 'job=~"node-exporter"') +
          // Add k8s cluster nodes rules
          hostRules($._config.prometheusRules.alertGroupCluster, 'job=~"node-exporter"') +
          // Add hosts rules
          (
            if std.length([$._config.hostMonitoring.hosts]) > 0 && $._config.hostMonitoring.enabled then
              hostRules($._config.prometheusRules.alertGroupHost, 'job!~"node-exporter"')
            else
              []
          )
        ),
      ],
    },
  },
}
