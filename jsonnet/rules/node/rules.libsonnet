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

/* K8s prometheus rules */

{
  prometheusRules+:: {
    'node.rules': {
      groups: [
        local diskExpr(metric) = 'sum(node_filesystem_%s_bytes{job="node-exporter", device!="rootfs"} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)' % metric;
        local diskUsed = '(%s - %s)' % [diskExpr('size'), diskExpr('free')];

        $.newRuleGroup('node.rules')
        .addAlertPair(
          name='CPUAvgHigh',
          message='High Avg CPU Cluster Utilization {{ $value }}%',
          expr='round((1 - (avg(irate(node_cpu_seconds_total{job="node-exporter",mode="idle"}[5m])))) * 100)',
          thresholds=$._config.thresholds.node,
        )
        .addAlertPair(
          name='CPUOverallHigh',
          message='"{{ $labels.nodename }}": High CPU Utilization {{ $value }}%',
          expr='round((1 - (avg(irate(node_cpu_seconds_total{job="node-exporter",mode="idle"}[5m]) * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename) )) * 100)',
          thresholds=$._config.thresholds.node,
        )
        .addAlertPair(
          name='RAMAvgHigh',
          message='High Avg RAM Cluster Utilization {{ $value }}%',
          expr='round((1 - sum(node_memory_MemAvailable_bytes{job="node-exporter"}) / sum(node_memory_MemTotal_bytes{job="node-exporter"})) * 100)',
          thresholds=$._config.thresholds.node,
        )
        .addAlertPair(
          name='RAMOverallHigh',
          message='"{{ $labels.nodename }}": High RAM Utilization {{ $value }}%',
          expr='round((1 - sum by (job, nodename) (node_memory_MemAvailable_bytes{job="node-exporter"} * on(instance) group_left(nodename) (node_uname_info)) / sum by (job, nodename) (node_memory_MemTotal_bytes{job="node-exporter"} * on(instance) group_left(nodename) (node_uname_info))) * 100)',
          thresholds=$._config.thresholds.node,
        )
        .addAlertPair(
          name='DiskAvgHigh',
          message='High Avg Disk Cluster Utilization {{ $value }}%',
          expr='round(avg((sum(node_filesystem_size_bytes{job="node-exporter", device!="rootfs"}) by (device) - sum(node_filesystem_free_bytes{job="node-exporter", device!="rootfs"}) by (device)) / (sum(node_filesystem_size_bytes{job="node-exporter", device!="rootfs"}) by (device) - sum(node_filesystem_free_bytes{job="node-exporter", device!="rootfs"}) by (device) + sum(node_filesystem_avail_bytes{job="node-exporter", device!="rootfs"}) by (device)) * 100))',
          thresholds=$._config.thresholds.node,
        )
        .addAlertPair(
          name='DiskOverallHigh',
          message='"{{ $labels.nodename }}": High Disk Utilization {{ $value }}%',
          expr='round(%s / (%s + %s) * 100)' % [diskUsed, diskUsed, diskExpr('avail')],
          thresholds=$._config.thresholds.node,
        )
        .addAlertPair(
          name='NetworkErrorsHigh',
          message='"{{ $labels.nodename }}": High Network Errors Count {{ $value }}',
          expr='sum(rate(node_network_transmit_errs_total{job="node-exporter", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"} [5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename) + sum(rate(node_network_receive_errs_total{job="node-exporter", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename)',
          thresholds=$._config.thresholds.networkErrors,
        ),
      ],
    },
  },
}
