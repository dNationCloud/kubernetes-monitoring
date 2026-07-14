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

/* K8s python flask dashboard */
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
    'python-flask':
      local color = $._config.grafanaDashboards.color;

      local colorOverride(alias, col) = fieldOverride.byRegexp.new(alias)
                                          + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: col });

      local promTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local lokiTarget(expr, legendFormat=null) =
        loki.withExpr(expr) + (if legendFormat != null then loki.withLegendFormat(legendFormat) else {});

      local legendTable(calcs, sortBy=null) =
        timeSeriesPanel.options.legend.withDisplayMode('table')
        + timeSeriesPanel.options.legend.withPlacement('right')
        + timeSeriesPanel.options.legend.withCalcs(calcs)
        + (if sortBy != null then timeSeriesPanel.options.legend.withSortBy(sortBy) + timeSeriesPanel.options.legend.withSortDesc(true) else {});

      local timeSeriesBase(title) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc');

      local timeSeriesStacked(title) =
        timeSeriesBase(title)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false);

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
        timeSeriesStacked('CPU Usage') + timeSeriesPanel.standardOptions.withUnit('core') + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.standardOptions.withOverrides(podReqLimitOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", container=~"$container"}) by ($view)', '{{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_requests{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodRequests - {{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_limits{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodLimits - {{$view}}'),
        ]);

      local memory =
        timeSeriesStacked('Memory Usage') + timeSeriesPanel.standardOptions.withUnit('bytes') + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.standardOptions.withOverrides(podReqLimitOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(container_memory_working_set_bytes{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", id!="", container!="POD", container=~"$container"}) by ($view)', '{{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_requests{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodRequests - {{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_limits{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodLimits - {{$view}}'),
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
        + timeSeriesPanel.standardOptions.withUnit('short') + timeSeriesPanel.standardOptions.withMin(0)
        + legendTable(['lastNotNull'], 'Last *')
        + timeSeriesPanel.standardOptions.withOverrides([
          fieldOverride.byRegexp.new('Value #A')
            + fieldOverride.byRegexp.withProperty('custom.hideFrom', { legend: true, tooltip: false, viz: true }),
        ])
        + timeSeriesPanel.queryOptions.withTargets([
          lokiTarget('sum(count_over_time({cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"[10s])) by ($view)', '{{$view}}'),
        ])
        + timeSeriesPanel.queryOptions.withDatasource('loki', '$datasource_logs');

      local logs =
        logPanel.new('Logs')
        + logPanel.queryOptions.withDatasource('loki', '$datasource_logs')
        + logPanel.options.withShowLabels(true)
        + logPanel.queryOptions.withTargets([
          lokiTarget('{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"'),
        ]);

      local requestPerMinute =
        timeSeriesStacked('Total requests per minute')
        + legendTable(['max', 'lastNotNull'])
        + timeSeriesPanel.standardOptions.withOverrides([colorOverride('HTTP 500', color.red)])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(increase(\n  flask_http_request_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m]\n) / 2) by (status, $view)', 'HTTP {{status}} - {{$view}}'),
        ]);

      local errorsPerMinute =
        timeSeriesBase('Errors per minute')
        + legendTable(['max', 'lastNotNull'])
        + timeSeriesPanel.standardOptions.withOverrides([colorOverride('errors', color.orange)])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(\n  rate(\n    flask_http_request_duration_seconds_count{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status!="200"}[1m]\n)\n) by (status, $view)', 'HTTP {{status}} - {{$view}}'),
        ]);

      local averageResponseTime =
        timeSeriesBase('Average response time [1m]') + timeSeriesPanel.standardOptions.withUnit('s')
        + legendTable(['mean', 'max', 'min'], 'Mean')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('avg(rate(\n  flask_http_request_duration_seconds_sum{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200"}[1m]\n)\n /\nrate(\n  flask_http_request_duration_seconds_count{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200"}[1m]\n) >= 0)  by (status, $view)', 'HTTP 200 - {{$view}}'),
        ]);

      local requestUnder =
        timeSeriesBase('Requests under 250ms') + timeSeriesPanel.standardOptions.withUnit('none')
        + legendTable(['mean', 'max', 'min'], 'Mean')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(increase(\n  flask_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200",le="0.25"}[1m]\n)\n / ignoring (le)\nincrease(\n  flask_http_request_duration_seconds_count{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200"}[1m]\n) >= 0) by (status, $view)', 'HTTP 200 - {{$view}}'),
        ]);

      local requestDurationP50 =
        timeSeriesBase('Request duration [s] - p50')
        + timeSeriesPanel.panelOptions.withDescription('The 50th percentile of request durations over the last 60 seconds. In other words, half of the requests finish in (min/max/avg) these times.')
        + legendTable(['mean', 'max', 'min'], 'Mean')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('avg(histogram_quantile(\n  0.5,\n  rate(\n    flask_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200"}[1m]\n  )\n)>=0) by (status, $view)', 'HTTP 200 - {{$view}}'),
        ]);

      local requestDurationP90 =
        timeSeriesBase('Request duration [s] - p90')
        + timeSeriesPanel.panelOptions.withDescription('The 90th percentile of request durations over the last 60 seconds. In other words, 90 percent of the requests finish in (min/max/avg) these times.')
        + legendTable(['mean', 'max', 'min'], 'Mean')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('avg(histogram_quantile(\n  0.9,\n  rate(\n    flask_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200"}[1m]\n  )\n)>=0) by (status, $view)', 'HTTP 200 - {{$view}}'),
        ]);

      local templates =
        [$.grafanaTemplates.datasourceTemplate()]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.datasourceLogsTemplate()] else [])
        + [
          $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
          $.grafanaTemplates.jobTemplate('label_values(flask_exporter_info{cluster="$cluster"}, job)'),
          $.grafanaTemplates.viewByTemplate('pod,container'),
          $.grafanaTemplates.namespaceTemplate('label_values(flask_exporter_info{cluster="$cluster", job=~"$job"}, namespace)'),
          $.grafanaTemplates.podTemplate('label_values(flask_exporter_info{cluster="$cluster", job=~"$job", namespace=~"$namespace"}, pod)'),
          $.grafanaTemplates.containerTemplate('label_values(flask_exporter_info{cluster="$cluster", job=~"$job", namespace=~"$namespace"}, container)'),
        ]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.searchTemplate()] else []);

      local logsPanels = [
        row.new('Logs') + { gridPos: { x: 0, y: 54, w: 24, h: 1 } },
        count { gridPos: { x: 0, y: 55, w: 24, h: 5 } },
        logs { gridPos: { x: 0, y: 60, w: 24, h: 13 } },
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
        requestPerMinute { gridPos: { x: 0, y: 33, w: 12, h: 7 } },
        errorsPerMinute { gridPos: { x: 12, y: 33, w: 12, h: 7 } },
        averageResponseTime { gridPos: { x: 0, y: 40, w: 12, h: 7 } },
        requestUnder { gridPos: { x: 12, y: 40, w: 12, h: 7 } },
        requestDurationP50 { gridPos: { x: 0, y: 47, w: 12, h: 7 } },
        requestDurationP90 { gridPos: { x: 12, y: 47, w: 12, h: 7 } },
      ] + (if $._config.grafanaDashboards.isLoki then logsPanels else []);

      dashboard.new('Python Flask')
      + dashboard.withUid($._config.grafanaDashboards.ids.pythonFlask)
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
