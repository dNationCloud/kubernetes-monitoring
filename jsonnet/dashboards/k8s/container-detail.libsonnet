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

/* K8s container detail dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local logPanel = grafana.panel.logs;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;
local loki = grafana.query.loki;
local fieldOverride = grafana.panel.timeSeries.fieldOverride;

{
  grafanaDashboards+:: {
    'container-detail':
      local color = $._config.grafanaDashboards.color;

      local promTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local lokiTarget(expr, legendFormat=null) =
        loki.withExpr(expr) + (if legendFormat != null then loki.withLegendFormat(legendFormat) else {});

      local timeSeriesStacked(title) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc');

      local podReqLimitOverrides = [
        fieldOverride.byRegexp.new('/PodRequests/')
          + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: color.red })
          + fieldOverride.byRegexp.withProperty('custom.lineStyle', { fill: 'dash' })
          + fieldOverride.byRegexp.withProperty('custom.fillOpacity', 0)
          + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'none' })
          + fieldOverride.byRegexp.withProperty('custom.hideFrom', { tooltip: true, legend: false, viz: false }),
        fieldOverride.byRegexp.new('/PodLimits/')
          + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: color.orange })
          + fieldOverride.byRegexp.withProperty('custom.lineStyle', { fill: 'dash' })
          + fieldOverride.byRegexp.withProperty('custom.fillOpacity', 0)
          + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'none' })
          + fieldOverride.byRegexp.withProperty('custom.hideFrom', { tooltip: true, legend: false, viz: false }),
      ];

      local rxTxOverrides = [
        fieldOverride.byRegexp.new('/Rx_/')
          + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'B' })
          + fieldOverride.byRegexp.withProperty('custom.transform', 'negative-Y'),
        fieldOverride.byRegexp.new('/Tx_/')
          + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'A' }),
      ];

      local cpu =
        timeSeriesStacked('CPU Usage') + timeSeriesPanel.standardOptions.withUnit('cores')
        + timeSeriesPanel.standardOptions.withOverrides(podReqLimitOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", container=~"$container"}) by ($view)', '{{$view}}'),
          promTarget('sum(kube_pod_container_resource_requests{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'PodRequests - {{$view}}'),
          promTarget('sum(kube_pod_container_resource_limits{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'PodLimits - {{$view}}'),
        ]);

      local memory =
        timeSeriesStacked('Memory Usage') + timeSeriesPanel.standardOptions.withUnit('bytes')
        + timeSeriesPanel.standardOptions.withOverrides(podReqLimitOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(container_memory_working_set_bytes{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", id!="", container=~"$container"}) by ($view)', '{{$view}}'),
          promTarget('sum(kube_pod_container_resource_requests{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'PodRequests - {{$view}}'),
          promTarget('sum(kube_pod_container_resource_limits{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'PodLimits - {{$view}}'),
        ]);

      local bandwidth =
        timeSeriesStacked('Transmit/Receive Bandwidth') + timeSeriesPanel.standardOptions.withUnit('Bps')
        + timeSeriesPanel.standardOptions.withOverrides(rxTxOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(container_network_transmit_bytes_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Tx_{{pod}}'),
          promTarget('sum(irate(container_network_receive_bytes_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Rx_{{pod}}'),
        ]);

      local drops =
        timeSeriesStacked('Transmit/Receive Drops') + timeSeriesPanel.standardOptions.withUnit('pps')
        + timeSeriesPanel.standardOptions.withOverrides(rxTxOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(container_network_transmit_packets_dropped_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Tx_{{pod}}'),
          promTarget('sum(irate(container_network_receive_packets_dropped_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Rx_{{pod}}'),
        ]);

      local count =
        timeSeriesStacked('Count (avg for 10s intervals)')
        + timeSeriesPanel.standardOptions.withUnit('short')
        + timeSeriesPanel.options.legend.withDisplayMode('table') + timeSeriesPanel.options.legend.withPlacement('right')
        + timeSeriesPanel.options.legend.withCalcs(['lastNotNull']) + timeSeriesPanel.options.legend.withSortBy('Last *') + timeSeriesPanel.options.legend.withSortDesc(true)
        + timeSeriesPanel.standardOptions.withOverrides([fieldOverride.byRegexp.new('Value #A')
                                                           + fieldOverride.byRegexp.withProperty('custom.hideFrom', { legend: true, tooltip: false, viz: true })])
        + timeSeriesPanel.queryOptions.withTargets([lokiTarget('sum(count_over_time({cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"[10s])) by ($view)', '{{$view}}')])
        + timeSeriesPanel.queryOptions.withDatasource('loki', '$datasource_logs');

      local logs =
        logPanel.new('Logs')
        + logPanel.queryOptions.withDatasource('loki', '$datasource_logs') + logPanel.options.withShowLabels(true)
        + logPanel.queryOptions.withTargets([lokiTarget('{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"')]);

      local templates =
        [$.grafanaTemplates.datasourceTemplate()]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.datasourceLogsTemplate()] else [])
        + [
          $.grafanaTemplates.viewByTemplate('pod,container'),
          $.grafanaTemplates.clusterTemplate('label_values(node_namespace_pod_container:container_memory_working_set_bytes, cluster)'),
          $.grafanaTemplates.instanceTemplate('label_values(node_namespace_pod_container:container_memory_working_set_bytes{cluster="$cluster"}, node)', label='Node'),
          $.grafanaTemplates.namespaceTemplate('label_values(node_namespace_pod_container:container_memory_working_set_bytes{cluster="$cluster", node=~"$instance"}, namespace)'),
          $.grafanaTemplates.podTemplate('label_values(node_namespace_pod_container:container_memory_working_set_bytes{cluster="$cluster", node=~"$instance", namespace=~"$namespace"}, pod)'),
          $.grafanaTemplates.containerTemplate('label_values(node_namespace_pod_container:container_memory_working_set_bytes{cluster="$cluster", node=~"$instance", namespace=~"$namespace", pod=~"$pod"}, container)'),
        ]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.searchTemplate()] else []);

      local logsPanels = [
        row.new('Logs') + { gridPos: { x: 0, y: 32, w: 24, h: 1 } },
        count { gridPos: { x: 0, y: 33, w: 24, h: 5 } },
        logs { gridPos: { x: 0, y: 38, w: 24, h: 13 } },
      ];

      local panels = [
        row.new('CPU Usage') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        cpu { gridPos: { x: 0, y: 1, w: 24, h: 7 } },
        row.new('Memory Usage') + { gridPos: { x: 0, y: 8, w: 24, h: 1 } },
        memory { gridPos: { x: 0, y: 9, w: 24, h: 7 } },
        row.new('Network Bandwidth') + { gridPos: { x: 0, y: 16, w: 24, h: 1 } },
        bandwidth { gridPos: { x: 0, y: 17, w: 24, h: 7 } },
        row.new('Network Drops') + { gridPos: { x: 0, y: 24, w: 24, h: 1 } },
        drops { gridPos: { x: 0, y: 25, w: 24, h: 7 } },
      ] + (if $._config.grafanaDashboards.isLoki then logsPanels else []);

      dashboard.new('Container Detail')
      + dashboard.withUid($._config.grafanaDashboards.ids.containerDetail)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sContainer)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables(templates)
      + dashboard.withPanels(panels),
  },
}
