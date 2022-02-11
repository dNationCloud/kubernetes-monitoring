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

/* Websocket dashboard */
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;

{
  grafanaDashboards+:: {
    websocket:
      local memory =
        statPanel.new(
          title='Memory usage',
          datasource='$datasource',
          unit='bytes',
          reducerFunction='last',
          fields='/^Value$/',
          graphMode='none',
        ).addThresholds(
          [
            { color: $._config.grafanaDashboards.color.green, value: null },
          ]
        )
        .addTarget(prometheus.target('sum(container_memory_usage_bytes{pod=~"mt-websocket-.*", namespace="$namespace",container!="", container!="POD"})', legendFormat=''));

      local cpu =
        statPanel.new(
          title='CPU usage',
          datasource='$datasource',
          unit='short',
        ).addThresholds(
          [
            { color: $._config.grafanaDashboards.color.green, value: null },
            { color: $._config.grafanaDashboards.color.red, value: 80 },
          ]
        )
        .addTarget(prometheus.target('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate{namespace=~"$namespace", pod=~"mt-websocket.*", container!=""})', legendFormat=''));

      local traffic =
        statPanel.new(
          title='Network traffic',
          datasource='$datasource',
          unit='bytes',
        ).addThresholds(
          [
            { color: $._config.grafanaDashboards.color.green, value: null },
          ]
        )
        .addTargets(
          [
            prometheus.target('sum(rate(container_network_transmit_bytes_total{namespace=~"$namespace", pod=~"mt-websocket-.*"}[10m]))', legendFormat='transmit'),
            prometheus.target('sum(rate(container_network_receive_bytes_total{namespace=~"$namespace", pod=~"mt-websocket-.*"}[10m]))', legendFormat='receive'),
          ],
        );

      local fileSystem =
        statPanel.new(
          title='Filesystem usage',
          datasource='$datasource',
          unit='bytes',
        ).addThresholds(
          [
            { color: $._config.grafanaDashboards.color.green, value: null },
          ]
        )
        .addTarget(prometheus.target('sum(container_fs_usage_bytes{pod=~"mt-websocket-.*", namespace="$namespace", container!="POD", container!=""})', legendFormat=''));


      local activeConnnections =
        graphPanel.new(
          title='Active connections',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('sum by(connections)(om_customer_connections{namespace="$namespace",service="mt-websocket"})', legendFormat='{{ connections }}'));


      local eventRate =
        graphPanel.new(
          title='Event rate / 10min',
          datasource='$datasource',
          logBase1Y=2,
          logBase2Y=2,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(om_mq_recv_total{namespace="$namespace", service="mt-websocket"}[10m]))', legendFormat='MQ received'),
            prometheus.target('sum(rate(om_ws_send_total{namespace="$namespace", service="mt-websocket"}[10m]))', legendFormat='WS sent'),
            prometheus.target('sum(rate(om_ws_received_total{namespace="$namespace", service="mt-websocket"}[10m]))', legendFormat='WS received'),
            prometheus.target('sum(rate(om_ws_broadcast_total{namespace="$namespace", service="mt-websocket"}[10m]))', legendFormat='WS broadcast'),
            prometheus.target('sum(rate(om_ws_disconn_total{namespace="$namespace", service="mt-websocket"}[10m]))', legendFormat='WS disconnected'),
            prometheus.target('sum(rate(om_ws_connected_total{namespace="$namespace", service="mt-websocket"}[10m]))', legendFormat='WS connected'),
          ],
        );

      local sentFrames =
        graphPanel.new(
          title='Sent frames rate / 10min',
          datasource='$datasource',
          logBase1Y=2,
          logBase2Y=2,
        )
        .addTarget(prometheus.target('sum by(writes)(rate(om_customer_writes_total{namespace="$namespace"}[10m]))', legendFormat='{{ writes }}'));

      local errorRate =
        graphPanel.new(
          title='Connection error rate / 10min',
          datasource='$datasource',
        )
        .addTargets(
          [
            prometheus.target('sum(rate(om_ws_conn_abort_total{namespace="$namespace", service="mt-websocket"}[10m]))', legendFormat='Aborted WS connections'),
            prometheus.target('sum(rate(om_mq_conn_abort_total{namespace="$namespace", service="mt-websocket"}[10m]))', legendFormat='Aborted MQ connections'),
            prometheus.target('sum(rate(om_mq_reconnect_total{namespace="$namespace", service="mt-websocket"}[10m]))', legendFormat='MQ reconnects'),
            prometheus.target('sum(rate(om_ws_invalid{namespace="$namespace", service="mt-websocket"}[10m]))', legendFormat='WS invalid'),
          ],
        );

      local threads =
        graphPanel.new(
          title='Threads cumulative',
          description='Sum of all threads across all pods',
          datasource='$datasource',
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_threads_current{namespace="$namespace",service="mt-websocket"})', legendFormat='current'),
            prometheus.target('sum by(state)(jvm_threads_state{namespace="$namespace",service="mt-websocket"})', legendFormat='{{ state }}'),
          ],
        );

      local memoryPoolAllocation =
        graphPanel.new(
          title='Memory pool allocation rate / 10min',
          description='Memory pool allocation rate, cumulative from all pods',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('sum by(pool)(rate(jvm_memory_pool_allocated_bytes_total{namespace="$namespace", service="mt-websocket"}[10m]))', legendFormat='{{pool}}'));

      local bytes =
        graphPanel.new(
          title='Bytes used',
          description='Cumulative memory usage by all pods',
          datasource='$datasource',
          formatY1='bytes',
        )
        .addTarget(prometheus.target('sum(jvm_memory_bytes_used{namespace="$namespace",area="heap",service="mt-websocket"})', legendFormat='used bytes'));


      local panels = [
        memory { gridPos: { x: 0, y: 0, w: 6, h: 4 } },
        cpu { gridPos: { x: 6, y: 0, w: 6, h: 4 } },
        traffic { gridPos: { x: 12, y: 0, w: 6, h: 4 } },
        fileSystem { gridPos: { x: 18, y: 0, w: 6, h: 4 } },
        row.new('Connections') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
        activeConnnections { gridPos: { x: 0, y: 5, w: 24, h: 7 } },
        row.new('Events and frames') { gridPos: { x: 0, y: 12, w: 24, h: 1 } },
        eventRate { gridPos: { x: 0, y: 13, w: 24, h: 6 } },
        sentFrames { gridPos: { x: 0, y: 19, w: 24, h: 7 } },
        row.new('Errors') { gridPos: { x: 0, y: 26, w: 24, h: 1 } },
        errorRate { gridPos: { x: 0, y: 27, w: 24, h: 6 } },
        row.new('JVM') { gridPos: { x: 0, y: 33, w: 24, h: 1 } },
        threads { gridPos: { x: 0, y: 34, w: 24, h: 7 } },
        memoryPoolAllocation { gridPos: { x: 0, y: 41, w: 24, h: 8 } },
        bytes { gridPos: { x: 0, y: 49, w: 24, h: 7 } },
      ];

      dashboard.new(
        'Websocket',
        description='Websocket summary',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.websocket,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.namespaceTemplate('label_values(om_ws_active{}, namespace)', includeAll=false, multi=false),
      ])
      .addPanels(panels),
  },
}
