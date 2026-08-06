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
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    websocket:
      local statBase(title, unit, calc, gmode, steps, fields=null) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit(unit)
        + statPanel.options.withColorMode('value')
        + statPanel.options.withGraphMode(gmode)
        + statPanel.options.reduceOptions.withCalcs([calc])
        + statPanel.options.reduceOptions.withValues(false)
        + (if fields != null then statPanel.options.reduceOptions.withFields(fields) else {})
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps(steps);

      local memory =
        statBase('Memory usage', 'bytes', 'last', 'none', [{ color: $._config.grafanaDashboards.color.green, value: null }], '/^Value$/')
        + statPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(container_memory_usage_bytes{pod=~"mt-websocket-.*", namespace="$namespace",container!="", container!="POD"})'),
        ]);

      local cpu =
        statBase('CPU usage', 'short', 'mean', 'area', [{ color: $._config.grafanaDashboards.color.green, value: null }, { color: $._config.grafanaDashboards.color.red, value: 80 }])
        + statPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate{namespace=~"$namespace", pod=~"mt-websocket.*", container!=""})'),
        ]);

      local traffic =
        statBase('Network traffic', 'bytes', 'mean', 'area', [{ color: $._config.grafanaDashboards.color.green, value: null }])
        + statPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(rate(container_network_transmit_bytes_total{namespace=~"$namespace", pod=~"mt-websocket-.*"}[10m]))') + prometheus.withLegendFormat('transmit'),
          prometheus.withExpr('sum(rate(container_network_receive_bytes_total{namespace=~"$namespace", pod=~"mt-websocket-.*"}[10m]))') + prometheus.withLegendFormat('receive'),
        ]);

      local fileSystem =
        statBase('Filesystem usage', 'bytes', 'mean', 'area', [{ color: $._config.grafanaDashboards.color.green, value: null }])
        + statPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(container_fs_usage_bytes{pod=~"mt-websocket-.*", namespace="$namespace", container!="POD", container!=""})'),
        ]);

      local timeSeriesBase(title) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10);

      local logY2 =
        timeSeriesPanel.fieldConfig.defaults.custom.scaleDistribution.withType('log')
        + timeSeriesPanel.fieldConfig.defaults.custom.scaleDistribution.withLog(2);

      local activeConnnections =
        timeSeriesBase('Active connections')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum by(connections)(om_customer_connections{namespace="$namespace",service="mt-websocket"})') + prometheus.withLegendFormat('{{ connections }}'),
        ]);

      local eventRate =
        timeSeriesBase('Event rate / 10min')
        + logY2
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(rate(om_mq_recv_total{namespace="$namespace", service="mt-websocket"}[10m]))') + prometheus.withLegendFormat('MQ received'),
          prometheus.withExpr('sum(rate(om_ws_send_total{namespace="$namespace", service="mt-websocket"}[10m]))') + prometheus.withLegendFormat('WS sent'),
          prometheus.withExpr('sum(rate(om_ws_received_total{namespace="$namespace", service="mt-websocket"}[10m]))') + prometheus.withLegendFormat('WS received'),
          prometheus.withExpr('sum(rate(om_ws_broadcast_total{namespace="$namespace", service="mt-websocket"}[10m]))') + prometheus.withLegendFormat('WS broadcast'),
          prometheus.withExpr('sum(rate(om_ws_disconn_total{namespace="$namespace", service="mt-websocket"}[10m]))') + prometheus.withLegendFormat('WS disconnected'),
          prometheus.withExpr('sum(rate(om_ws_connected_total{namespace="$namespace", service="mt-websocket"}[10m]))') + prometheus.withLegendFormat('WS connected'),
        ]);

      local sentFrames =
        timeSeriesBase('Sent frames rate / 10min')
        + logY2
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum by(writes)(rate(om_customer_writes_total{namespace="$namespace"}[10m]))') + prometheus.withLegendFormat('{{ writes }}'),
        ]);

      local errorRate =
        timeSeriesBase('Connection error rate / 10min')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(rate(om_ws_conn_abort_total{namespace="$namespace", service="mt-websocket"}[10m]))') + prometheus.withLegendFormat('Aborted WS connections'),
          prometheus.withExpr('sum(rate(om_mq_conn_abort_total{namespace="$namespace", service="mt-websocket"}[10m]))') + prometheus.withLegendFormat('Aborted MQ connections'),
          prometheus.withExpr('sum(rate(om_mq_reconnect_total{namespace="$namespace", service="mt-websocket"}[10m]))') + prometheus.withLegendFormat('MQ reconnects'),
          prometheus.withExpr('sum(rate(om_ws_invalid{namespace="$namespace", service="mt-websocket"}[10m]))') + prometheus.withLegendFormat('WS invalid'),
        ]);

      local threads =
        timeSeriesBase('Threads cumulative')
        + timeSeriesPanel.panelOptions.withDescription('Sum of all threads across all pods')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(jvm_threads_current{namespace="$namespace",service="mt-websocket"})') + prometheus.withLegendFormat('current'),
          prometheus.withExpr('sum by(state)(jvm_threads_state{namespace="$namespace",service="mt-websocket"})') + prometheus.withLegendFormat('{{ state }}'),
        ]);

      local memoryPoolAllocation =
        timeSeriesBase('Memory pool allocation rate / 10min')
        + timeSeriesPanel.panelOptions.withDescription('Memory pool allocation rate, cumulative from all pods')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum by(pool)(rate(jvm_memory_pool_allocated_bytes_total{namespace="$namespace", service="mt-websocket"}[10m]))') + prometheus.withLegendFormat('{{pool}}'),
        ]);

      local bytes =
        timeSeriesBase('Bytes used')
        + timeSeriesPanel.panelOptions.withDescription('Cumulative memory usage by all pods')
        + timeSeriesPanel.standardOptions.withUnit('bytes')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(jvm_memory_bytes_used{namespace="$namespace",area="heap",service="mt-websocket"})') + prometheus.withLegendFormat('used bytes'),
        ]);

      local panels = [
        memory { gridPos: { x: 0, y: 0, w: 6, h: 4 } },
        cpu { gridPos: { x: 6, y: 0, w: 6, h: 4 } },
        traffic { gridPos: { x: 12, y: 0, w: 6, h: 4 } },
        fileSystem { gridPos: { x: 18, y: 0, w: 6, h: 4 } },
        row.new('Connections') + { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
        activeConnnections { gridPos: { x: 0, y: 5, w: 24, h: 7 } },
        row.new('Events and frames') + { gridPos: { x: 0, y: 12, w: 24, h: 1 } },
        eventRate { gridPos: { x: 0, y: 13, w: 24, h: 6 } },
        sentFrames { gridPos: { x: 0, y: 19, w: 24, h: 7 } },
        row.new('Errors') + { gridPos: { x: 0, y: 26, w: 24, h: 1 } },
        errorRate { gridPos: { x: 0, y: 27, w: 24, h: 6 } },
        row.new('JVM') + { gridPos: { x: 0, y: 33, w: 24, h: 1 } },
        threads { gridPos: { x: 0, y: 34, w: 24, h: 7 } },
        memoryPoolAllocation { gridPos: { x: 0, y: 41, w: 24, h: 8 } },
        bytes { gridPos: { x: 0, y: 49, w: 24, h: 7 } },
      ];

      dashboard.new('Websocket')
      + dashboard.withDescription('Websocket summary')
      + dashboard.withUid($._config.grafanaDashboards.ids.websocket)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.namespaceTemplate('label_values(om_ws_active{}, namespace)', includeAll=false, multi=false),
      ])
      + dashboard.withPanels(panels),
  },
}
