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

/* K8s nginx ingress dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local table = grafana.panel.table;
local fieldOverride = grafana.panel.table.fieldOverride;
local logPanel = grafana.panel.logs;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;
local loki = grafana.query.loki;

{
  grafanaDashboards+:: {
    'nginx-ingress':
      local color = $._config.grafanaDashboards.color;

      local promTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr)
        + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local tableTarget(expr) =
        prometheus.withExpr(expr) + prometheus.withFormat('table') + prometheus.withInstant(true);

      local lokiTarget(expr, dsl='$datasource_logs', legendFormat=null) =
        loki.withExpr(expr)
        + (if legendFormat != null then loki.withLegendFormat(legendFormat) else {});

      local cpu =
        timeSeriesPanel.new('CPU Usage')
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit('core')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + timeSeriesPanel.standardOptions.withOverrides([
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
        ])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", container=~"$container"}) by ($view)', '{{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_requests{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodRequests - {{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_limits{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodLimits - {{$view}}'),
        ]);

      local memory =
        timeSeriesPanel.new('Memory Usage')
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit('bytes')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + timeSeriesPanel.standardOptions.withOverrides([
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
        ])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(container_memory_working_set_bytes{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", id!="", container!="POD", container=~"$container"}) by ($view)', '{{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_requests{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodRequests - {{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_limits{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodLimits - {{$view}}'),
        ]);

      local bandwidth =
        timeSeriesPanel.new('Transmit/Receive Bandwidth')
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit('Bps')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + timeSeriesPanel.standardOptions.withOverrides([
          fieldOverride.byRegexp.new('/Rx_/')
            + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'B' })
            + fieldOverride.byRegexp.withProperty('custom.transform', 'negative-Y'),
          fieldOverride.byRegexp.new('/Tx_/')
            + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'A' }),
        ])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(container_network_transmit_bytes_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Tx_{{pod}}'),
          promTarget('sum(irate(container_network_receive_bytes_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Rx_{{pod}}'),
        ]);

      local drops =
        timeSeriesPanel.new('Transmit/Receive Drops')
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit('pps')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + timeSeriesPanel.standardOptions.withOverrides([
          fieldOverride.byRegexp.new('/Rx_/')
            + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'B' })
            + fieldOverride.byRegexp.withProperty('custom.transform', 'negative-Y'),
          fieldOverride.byRegexp.new('/Tx_/')
            + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'A' }),
        ])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(container_network_transmit_packets_dropped_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Tx_{{pod}}'),
          promTarget('sum(irate(container_network_receive_packets_dropped_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Rx_{{pod}}'),
        ]);

      local count =
        timeSeriesPanel.new('Count (avg for 10s intervals)')
        + timeSeriesPanel.queryOptions.withDatasource('loki', '$datasource_logs')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit('short')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
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
          lokiTarget('sum(count_over_time({cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"[10s])) by ($view)', '$datasource_logs', '{{$view}}'),
        ]);

      local logs =
        logPanel.new('Logs')
        + logPanel.queryOptions.withDatasource('loki', '$datasource_logs')
        + logPanel.options.withShowLabels(true)
        + logPanel.queryOptions.withTargets([
          lokiTarget('{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"', '$datasource_logs'),
        ]);

      local controllerRequestVolume =
        statPanel.new('Controller Request Volume')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit('reqps')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.queryOptions.withTargets([
          promTarget('round(sum(irate(nginx_ingress_controller_requests{cluster="$cluster", job=~"$job", controller_pod=~"$pod", namespace=~"$namespace", container=~"$container"}[5m])), 0.001)'),
        ]);

      local configReloads =
        statPanel.new('Config Reloads')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withDecimals(0)
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.queryOptions.withTargets([
          promTarget('avg(nginx_ingress_controller_success{cluster="$cluster", job=~"$job", controller_pod=~"$pod", controller_namespace=~"$namespace", container=~"$container"})'),
        ]);

      local controllerConnections =
        statPanel.new('Controller Connections')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.queryOptions.withTargets([
          promTarget('sum(avg_over_time(nginx_ingress_controller_nginx_process_connections{cluster="$cluster", job=~"$job", controller_pod=~"$pod", controller_namespace=~"$namespace", container=~"$container"}[5m]))'),
        ]);

      local configFailed =
        statPanel.new('Last Config Failed')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withNoValue('0')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.queryOptions.withTargets([
          promTarget('count(nginx_ingress_controller_config_last_reload_successful{cluster="$cluster", job=~"$job", controller_pod=~"$pod",controller_namespace=~"$namespace", container=~"$container"} == 0)'),
        ]);

      local controllerSuccessRate =
        statPanel.new('Controller Success Rate (non-4|5xx responses)')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.options.withColorMode('background')
        + statPanel.standardOptions.withUnit('percent')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps([
          { color: color.red, value: null },
          { color: color.orange, value: 75 },
          { color: color.green, value: 90 },
        ])
        + statPanel.queryOptions.withTargets([
          promTarget('sum(rate(nginx_ingress_controller_requests{cluster="$cluster", job=~"$job", controller_pod=~"$pod",namespace=~"$namespace",status!~"[4-5].*", container=~"$container"}[5m])) / sum(rate(nginx_ingress_controller_requests{cluster="$cluster", job=~"$job", controller_pod=~"$pod", namespace=~"$namespace", container=~"$container"}[5m])) * 100'),
        ]);

      local ingressRequestVolume =
        timeSeriesPanel.new('Ingress Request Volume')
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit('reqps')
        + timeSeriesPanel.standardOptions.withDecimals(2)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.options.legend.withDisplayMode('table')
        + timeSeriesPanel.options.legend.withPlacement('right')
        + timeSeriesPanel.options.legend.withCalcs(['mean'])
        + timeSeriesPanel.options.legend.withSortBy('Mean')
        + timeSeriesPanel.options.legend.withSortDesc(true)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('round(sum(irate(nginx_ingress_controller_requests{cluster="$cluster", job=~"$job", controller_pod=~"$pod", controller_namespace=~"$namespace", ingress=~"$ingress", container=~"$container"}[5m])) by (ingress), 0.001)', '{{ingress}}'),
        ]);

      local ingressSuccessRate =
        timeSeriesPanel.new('Ingress Success Rate (non-4|5xx responses)')
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit('percentunit')
        + timeSeriesPanel.standardOptions.withDecimals(2)
        + timeSeriesPanel.options.legend.withDisplayMode('table')
        + timeSeriesPanel.options.legend.withPlacement('right')
        + timeSeriesPanel.options.legend.withCalcs(['lastNotNull', 'mean', 'max', 'min'])
        + timeSeriesPanel.options.legend.withSortBy('Last *')
        + timeSeriesPanel.options.legend.withSortDesc(true)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(rate(nginx_ingress_controller_requests{cluster="$cluster", job=~"$job", controller_pod=~"$pod",namespace=~"$namespace",ingress=~"$ingress",status!~"[4-5].*",  container=~"$container"}[5m])) by (ingress) / sum(rate(nginx_ingress_controller_requests{cluster="$cluster", job=~"$job", controller_pod=~"$pod",namespace=~"$namespace",  container=~"$container", ingress=~"$ingress"}[5m])) by (ingress)', '{{ingress}}'),
        ]);

      local percentileTable =
        table.new('Ingress Percentile Response Times and Transfer Rates')
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + table.queryOptions.withTransformations([{ id: 'merge', options: {} }])
        + table.standardOptions.withOverrides([
          fieldOverride.byName.new('Time')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('ingress')
          + fieldOverride.byName.withProperty('displayName', 'Ingress'),
          fieldOverride.byName.new('Value #A')
          + fieldOverride.byName.withProperty('displayName', 'P50 Latency')
          + fieldOverride.byName.withProperty('unit', 'dtdurations')
          + fieldOverride.byName.withProperty('decimals', 0)
          + fieldOverride.byName.withProperty('custom.width', 149),
          fieldOverride.byName.new('Value #B')
          + fieldOverride.byName.withProperty('displayName', 'P90 Latency')
          + fieldOverride.byName.withProperty('unit', 'dtdurations')
          + fieldOverride.byName.withProperty('decimals', 0)
          + fieldOverride.byName.withProperty('custom.width', 149),
          fieldOverride.byName.new('Value #C')
          + fieldOverride.byName.withProperty('displayName', 'P99 Latency')
          + fieldOverride.byName.withProperty('unit', 'dtdurations')
          + fieldOverride.byName.withProperty('decimals', 0)
          + fieldOverride.byName.withProperty('custom.width', 149),
          fieldOverride.byName.new('Value #D')
          + fieldOverride.byName.withProperty('displayName', 'IN')
          + fieldOverride.byName.withProperty('unit', 'Bps')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 68),
          fieldOverride.byName.new('Value #E')
          + fieldOverride.byName.withProperty('displayName', 'OUT')
          + fieldOverride.byName.withProperty('unit', 'Bps')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 77),
        ])
        + table.queryOptions.withTargets([
          tableTarget('histogram_quantile(0.50, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{cluster="$cluster", job=~"$job", ingress!="", controller_pod=~"$pod",  container=~"$container", controller_namespace=~"$namespace", ingress=~"$ingress"}[5m])) by (le, ingress))'),
          tableTarget('histogram_quantile(0.90, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{cluster="$cluster", job=~"$job", ingress!="", controller_pod=~"$pod",  container=~"$container", controller_namespace=~"$namespace", ingress=~"$ingress"}[5m])) by (le, ingress))'),
          tableTarget('histogram_quantile(0.99, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{cluster="$cluster", job=~"$job", ingress!="", controller_pod=~"$pod",  container=~"$container", controller_namespace=~"$namespace", ingress=~"$ingress"}[5m])) by (le, ingress))'),
          tableTarget('sum(irate(nginx_ingress_controller_request_size_sum{cluster="$cluster", job=~"$job", ingress!="", controller_pod=~"$pod",  container=~"$container", controller_namespace=~"$namespace", ingress=~"$ingress"}[5m])) by (ingress)'),
          tableTarget('sum(irate(nginx_ingress_controller_response_size_sum{cluster="$cluster", job=~"$job", ingress!="", controller_pod=~"$pod",  container=~"$container", controller_namespace=~"$namespace", ingress=~"$ingress"}[5m])) by (ingress)'),
        ]);

      local certificateTable =
        table.new('Ingress Certificate Expiry')
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + table.queryOptions.withTransformations([{ id: 'merge', options: {} }])
        + table.standardOptions.withOverrides([
          fieldOverride.byName.new('Time')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('host')
          + fieldOverride.byName.withProperty('displayName', 'Host'),
          fieldOverride.byName.new('Value')
          + fieldOverride.byName.withProperty('displayName', 'TTL')
          + fieldOverride.byName.withProperty('unit', 's')
          + fieldOverride.byName.withProperty('decimals', 0)
          + fieldOverride.byName.withProperty('custom.cellOptions', { type: 'color-background' })
          + fieldOverride.byName.withProperty('thresholds', { mode: 'absolute', steps: [
            { color: color.red, value: null },
            { color: color.orange, value: 0 },
            { color: color.green, value: 8 * 24 * 60 * 60 },
          ] })
          + fieldOverride.byName.withProperty('custom.width', 77),
        ])
        + table.queryOptions.withTargets([
          tableTarget('avg(nginx_ingress_controller_ssl_expire_time_seconds{cluster="$cluster", job=~"$job", pod=~"$pod", namespace=~"$namespace", container=~"$container"}) by (host) - time()'),
        ]);

      local templates =
        [
          $.grafanaTemplates.datasourceTemplate(),
        ]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.datasourceLogsTemplate()] else [])
        + [
          $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
          $.grafanaTemplates.jobTemplate('label_values(nginx_ingress_controller_config_hash{cluster="$cluster"}, job)'),
          $.grafanaTemplates.viewByTemplate('pod,container'),
          $.grafanaTemplates.namespaceTemplate('label_values(nginx_ingress_controller_config_hash{cluster="$cluster", job=~"$job"}, controller_namespace)'),
          $.grafanaTemplates.podTemplate('label_values(nginx_ingress_controller_config_hash{cluster="$cluster", job=~"$job", namespace=~"$namespace"}, pod)'),
          $.grafanaTemplates.containerTemplate('label_values(nginx_ingress_controller_config_hash{cluster="$cluster", job=~"$job", namespace=~"$namespace"}, container)'),
          $.grafanaTemplates.baseTemplate('ingress', 'Ingress', 'label_values(nginx_ingress_controller_requests{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod"}, ingress)'),
        ]
        + if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.searchTemplate()] else [];

      local logsPanels = [
        row.new('Logs') + { gridPos: { x: 0, y: 69, w: 24, h: 1 } },
        count { gridPos: { x: 0, y: 70, w: 24, h: 5 } },
        logs { gridPos: { x: 0, y: 75, w: 24, h: 13 } },
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
        row.new('Ingress overview') + { gridPos: { x: 0, y: 32, w: 24, h: 1 } },
        controllerRequestVolume { gridPos: { x: 0, y: 33, w: 6, h: 3 } },
        configReloads { gridPos: { x: 6, y: 33, w: 6, h: 3 } },
        ingressRequestVolume { gridPos: { x: 12, y: 33, w: 12, h: 6 } },
        controllerConnections { gridPos: { x: 0, y: 36, w: 6, h: 3 } },
        configFailed { gridPos: { x: 6, y: 36, w: 6, h: 3 } },
        controllerSuccessRate { gridPos: { x: 0, y: 39, w: 24, h: 3 } },
        ingressSuccessRate { gridPos: { x: 0, y: 42, w: 24, h: 9 } },
        row.new('Ingress Percentile Response Times and Transfer Rates') + { gridPos: { x: 0, y: 51, w: 24, h: 1 } },
        percentileTable { gridPos: { x: 0, y: 52, w: 24, h: 8 } },
        row.new('Ingress Certificate Expiry') + { gridPos: { x: 0, y: 60, w: 24, h: 1 } },
        certificateTable { gridPos: { x: 6, y: 61, w: 24, h: 8 } },
      ] + if $._config.grafanaDashboards.isLoki then logsPanels else [];

      dashboard.new('Nginx Ingress')
      + dashboard.withUid($._config.grafanaDashboards.ids.nginxIngress)
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
