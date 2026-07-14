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

/* K8s nginx vts enhanced dashboard */
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
    'nginx-vts-enhanced':
      local color = $._config.grafanaDashboards.color;
      local tooltipDesc = timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc');

      local promTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local lokiTarget(expr, legendFormat=null) =
        loki.withExpr(expr) + (if legendFormat != null then loki.withLegendFormat(legendFormat) else {});

      local timeSeriesBase(title) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + tooltipDesc;

      local timeSeriesStacked(title) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + tooltipDesc;

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
        timeSeriesStacked('CPU Usage')
        + timeSeriesPanel.standardOptions.withUnit('core')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.standardOptions.withOverrides(podReqLimitOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container!~"POD|"}) by (container)', '{{container}}'),
          promTarget('sum(\nkube_pod_container_resource_requests{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod"})', 'PodRequests'),
          promTarget('sum(\nkube_pod_container_resource_limits{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod"})', 'PodLimits'),
        ]);

      local memory =
        timeSeriesStacked('Memory Usage')
        + timeSeriesPanel.standardOptions.withUnit('bytes')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.standardOptions.withOverrides(podReqLimitOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(container_memory_working_set_bytes{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", id!="", container!~"POD|"}) by (container)', '{{container}}'),
          promTarget('sum(\nkube_pod_container_resource_requests{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}) by (container)', 'PodRequests - {{container}}'),
          promTarget('sum(\nkube_pod_container_resource_limits{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}) by (container)', 'PodLimits - {{container}}'),
        ]);

      local bandwidth =
        timeSeriesStacked('Transmit/Receive Bandwidth')
        + timeSeriesPanel.standardOptions.withUnit('Bps')
        + timeSeriesPanel.standardOptions.withOverrides(rxTxOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(container_network_transmit_bytes_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Tx_{{pod}}'),
          promTarget('sum(irate(container_network_receive_bytes_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Rx_{{pod}}'),
        ]);

      local drops =
        timeSeriesStacked('Transmit/Receive Drops')
        + timeSeriesPanel.standardOptions.withUnit('pps')
        + timeSeriesPanel.standardOptions.withOverrides(rxTxOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(container_network_transmit_packets_dropped_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Tx_{{pod}}'),
          promTarget('sum(irate(container_network_receive_packets_dropped_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Rx_{{pod}}'),
        ]);

      local count =
        timeSeriesStacked('Count (avg for 10s intervals)')
        + timeSeriesPanel.standardOptions.withUnit('short')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.options.legend.withDisplayMode('table')
        + timeSeriesPanel.options.legend.withPlacement('right')
        + timeSeriesPanel.options.legend.withCalcs(['lastNotNull'])
        + timeSeriesPanel.options.legend.withSortBy('Last *')
        + timeSeriesPanel.options.legend.withSortDesc(true)
        + timeSeriesPanel.standardOptions.withOverrides([
          fieldOverride.byRegexp.new('Value #A')
            + fieldOverride.byRegexp.withProperty('custom.hideFrom', { legend: true, tooltip: false, viz: true }),
        ])
        + timeSeriesPanel.queryOptions.withTargets([
          lokiTarget('sum(count_over_time({cluster="$cluster", namespace=~"$namespace", pod=~"$pod"} |~ "(?i)$search"[10s])) by (pod)', '{{pod}}'),
        ])
        + timeSeriesPanel.queryOptions.withDatasource('loki', '$datasource_logs');

      local logs =
        logPanel.new('Logs')
        + logPanel.queryOptions.withDatasource('loki', '$datasource_logs')
        + logPanel.options.withShowLabels(true)
        + logPanel.queryOptions.withTargets([
          lokiTarget('{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"} |~ "(?i)$search"'),
        ]);

      local serverConnections =
        timeSeriesBase('Server Connections')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(nginx_vts_main_connections{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", status=~"active|writing|reading|waiting"}) by (status)', '{{status}}'),
        ]);

      local serverCache =
        timeSeriesBase('Server Cache')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(nginx_vts_server_cache_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", host=~"^$host$"}[5m])) by (status)', '{{status}}'),
        ]);

      local serverRequests =
        timeSeriesBase('Server Requests')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(nginx_vts_server_requests_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", host=~"^$host$", code!="total"}[5m])) by (code)', '{{code}}'),
        ]);

      local serverBytes =
        timeSeriesBase('Server Bytes')
        + timeSeriesPanel.standardOptions.withUnit('bytes')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", host=~"^$host$"}[5m])) by (direction)', '{{direction}}'),
        ]);

      local upstreamRequests =
        timeSeriesBase('Upstream Requests')
        + timeSeriesPanel.panelOptions.withDescription("This one is providing aggregated error codes, but it's still possible to graph these per upstream.")
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(nginx_vts_upstream_requests_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", upstream=~"^$upstream$", code!="total"}[5m])) by (code)', '{{code}}'),
        ]);

      local upstreamBytes =
        timeSeriesBase('Upstream Bytes')
        + timeSeriesPanel.standardOptions.withUnit('bytes')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(nginx_vts_upstream_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", upstream=~"^$upstream$"}[5m])) by (direction)', '{{direction}}'),
        ]);

      local upstreamBackendResponse =
        timeSeriesBase('Upstream Backend Response')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(nginx_vts_upstream_response_seconds{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", upstream=~"^$upstream$"}) by (backend)', '{{backend}}'),
        ]);

      local templates =
        [$.grafanaTemplates.datasourceTemplate()]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.datasourceLogsTemplate()] else [])
        + [
          $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
          $.grafanaTemplates.jobTemplate('label_values(nginx_vts_server_bytes_total{cluster="$cluster"}, job)'),
          $.grafanaTemplates.namespaceTemplate('label_values(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job"}, namespace)'),
          $.grafanaTemplates.podTemplate('label_values(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace"}, pod)'),
          $.grafanaTemplates.baseTemplate('host', 'Host', 'label_values(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod"}, host)'),
          $.grafanaTemplates.baseTemplate('upstream', 'Upstream', 'label_values(nginx_vts_upstream_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod"}, upstream)'),
        ]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.searchTemplate()] else []);

      local logsPanels = [
        row.new('Logs') + { gridPos: { x: 0, y: 62, w: 24, h: 1 } },
        count { gridPos: { x: 0, y: 63, w: 24, h: 5 } },
        logs { gridPos: { x: 0, y: 68, w: 24, h: 13 } },
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
        row.new('Server') + { gridPos: { x: 0, y: 32, w: 24, h: 1 } },
        serverConnections { gridPos: { x: 0, y: 33, w: 12, h: 7 } },
        serverCache { gridPos: { x: 12, y: 33, w: 12, h: 7 } },
        serverRequests { gridPos: { x: 0, y: 40, w: 12, h: 7 } },
        serverBytes { gridPos: { x: 12, y: 40, w: 12, h: 7 } },
        row.new('Upstream') + { gridPos: { x: 0, y: 47, w: 24, h: 1 } },
        upstreamRequests { gridPos: { x: 0, y: 48, w: 12, h: 7 } },
        upstreamBytes { gridPos: { x: 12, y: 48, w: 12, h: 7 } },
        upstreamBackendResponse { gridPos: { x: 0, y: 55, w: 24, h: 7 } },
      ] + (if $._config.grafanaDashboards.isLoki then logsPanels else []);

      dashboard.new('Nginx VTS Enhanced')
      + dashboard.withUid($._config.grafanaDashboards.ids.nginxVtsEnhanced)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables(templates)
      + dashboard.withPanels(panels),
  },
}
