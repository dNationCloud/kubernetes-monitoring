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

/* Lokid Distributed dashboard*/
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    'loki-distributed':
      local promTarget(expr, legendFormat=null, format=null) =
        prometheus.withExpr(expr)
        + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {})
        + (if format != null then prometheus.withFormat(format) else {});

      local timeSeriesBase(title, unit, fillOpacity, spanNullsFalse=true, calcs=[], sortBy=null) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit(unit)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(fillOpacity)
        + (if spanNullsFalse then timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false) else {})
        + (if std.length(calcs) > 0 then
             timeSeriesPanel.options.legend.withDisplayMode('list') + timeSeriesPanel.options.legend.withCalcs(calcs)
             + (if sortBy != null then timeSeriesPanel.options.legend.withSortBy(sortBy) else {})
           else {})
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc');

      local statBase(title, cmode, unit, steps) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit(unit)
        + statPanel.options.withColorMode(cmode)
        + statPanel.options.withGraphMode('none')
        + statPanel.options.reduceOptions.withCalcs(['last'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps(steps);

      local version =
        statBase('Loki Version', 'background', 'none', [])
        + statPanel.options.reduceOptions.withFields('/^version$/')
        + statPanel.queryOptions.withTargets([promTarget('loki_build_info{cluster="$cluster", job=~"$job"}', format='table')]);

      local msgs =
        statBase('Log Messages Total', 'value', 'short', [])
        + statPanel.queryOptions.withTargets([promTarget('sum(log_messages_total{cluster="$cluster", job=~"$job"})')]);

      local errors =
        statBase('Errors', 'background', 'none', [{ color: 'green', value: 0 }, { color: 'orange', value: 1 }])
        + statPanel.queryOptions.withTargets([promTarget('sum(log_messages_total{cluster="$cluster", job=~"$job",level="error"})')]);

      local panic =
        statBase('Panic', 'background', 'none', [{ color: 'green', value: 0 }, { color: 'red', value: 1 }])
        + statPanel.queryOptions.withTargets([promTarget('loki_panic_total{cluster="$cluster", job=~"$job"}', format='table')]);

      local msgs_graph(title, target) =
        timeSeriesBase(title, 'bytes', 10, calcs=['lastNotNull']) + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('histogram_quantile(0.95, sum(rate( %s {cluster="$cluster", job=~"$job"}[1m])) by (le,route))' % target, '{{route}}'),
        ]);

      local ingester_graph(title, target, legendFormat, format='short') =
        timeSeriesBase(title, format, 0, calcs=['lastNotNull'], sortBy='Last *')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('histogram_quantile(0.95, sum(rate( %s {cluster="$cluster", job=~"$job"}[1m])) by (le))' % target, legendFormat),
        ]);

      local querier_graph(title, target, format='short') =
        timeSeriesBase(title, format, 0, calcs=['lastNotNull'], sortBy='Last *') + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('%s{cluster="$cluster", job=~"$job"}' % target)]);

      local msgs_input =
        timeSeriesBase('Messages Input', 'short', 50, calcs=['lastNotNull'], sortBy='Last *')
        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(irate(log_messages_total{cluster="$cluster", job=~"$job"}[1m])) by (level)', '{{operation}}')]);

      local api_requests =
        timeSeriesBase('API Request Duration', 's', 0, calcs=['lastNotNull']) + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.95, sum(rate(loki_request_duration_seconds_bucket{cluster="$cluster", job=~"$job"}[5m])) by (le,route))', '{{route}}')]);

      local msgs_req_graph = msgs_graph('Request Size', 'loki_request_message_bytes_bucket');
      local msgs_resp_graph = msgs_graph('Response Size', 'loki_response_message_bytes_bucket');
      local ingester_blocks = ingester_graph('Blocks / Chunk', 'loki_ingester_blocks_per_chunk_bucket', 'blocks');
      local ingester_chunk_size = ingester_graph('Chunk Size', 'loki_ingester_chunk_size_bytes_bucket', 'chunk size', 'decbytes');
      local ingester_chunk_age = ingester_graph('Chunk Age', 'loki_ingester_chunk_age_seconds_bucket', 'ages', 's');
      local ingester_chunk_cmpratio = ingester_graph('Chunk Compression Ratios', 'loki_ingester_chunk_compression_ratio_bucket', 'ratio', 'percent');
      local ingester_chunk_enctime = ingester_graph('Chunk Encode Time', 'loki_ingester_chunk_encode_time_seconds_bucket', 'time', 's');
      local ingester_lines = ingester_graph('Lines / Chunk', 'loki_ingester_chunk_entries_bucket', 'lines', 'short');

      local cache_size =
        timeSeriesBase('Cache Value Size bytes', 'decbytes', 0) + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.95, sum(rate(loki_cache_value_size_bytes_bucket{cluster="$cluster", job=~"$job"}[5m])) by (le,name,method))', '{{name}} / {{method}}')]);

      local cache_fetched_keys =
        timeSeriesBase('Fetched Keys', 'short', 10, spanNullsFalse=false)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('loki_cache_fetched_keys{cluster="$cluster", job=~"$job"}', '{{container}}/{{name}}')]);

      local cache_hits_keys =
        timeSeriesBase('Hits Keys', 'short', 10, spanNullsFalse=false)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(loki_cache_hits{cluster="$cluster", job=~"$job"}[5m])', '{{container}}/{{name}}')]);

      local querier_cache_corruptions = querier_graph('Cache Corruptions', 'loki_querier_index_cache_corruptions_total');
      local querier_cache_errors = querier_graph('Cache Encode Errors', 'loki_querier_index_cache_encode_errors_total');
      local querier_cache_gets = querier_graph('Cache Gets', 'loki_querier_index_cache_gets_total');
      local querier_cache_hits = querier_graph('Cache Hits', 'loki_querier_index_cache_hits_total');
      local querier_cache_puts = querier_graph('Cache Puts', 'loki_querier_index_cache_puts_total');

      local panel_msgs(sy) = [
        row.new('Messages Input') + { gridPos: { x: 0, y: sy, w: 24, h: 1 } },
        msgs_input { gridPos: { x: 0, y: sy + 1, w: 24, h: 7 } },
      ];

      local panel_api(sy) = [
        row.new('API Requests') + { gridPos: { x: 0, y: sy, w: 24, h: 1 } },
        api_requests { gridPos: { x: 0, y: sy + 1, w: 24, h: 7 } },
        msgs_req_graph { gridPos: { x: 0, y: sy + 8, w: 12, h: 7 } },
        msgs_resp_graph { gridPos: { x: 12, y: sy + 8, w: 12, h: 7 } },
      ];

      local panel_ingester(sy) = [
        row.new('Ingester') + { gridPos: { x: 0, y: sy, w: 24, h: 1 } },
        ingester_blocks { gridPos: { x: 0, y: sy + 1, w: 8, h: 7 } },
        ingester_chunk_size { gridPos: { x: 8, y: sy + 1, w: 8, h: 7 } },
        ingester_chunk_age { gridPos: { x: 16, y: sy + 1, w: 8, h: 7 } },
        ingester_chunk_cmpratio { gridPos: { x: 0, y: sy + 8, w: 8, h: 7 } },
        ingester_chunk_enctime { gridPos: { x: 8, y: sy + 8, w: 8, h: 7 } },
        ingester_lines { gridPos: { x: 16, y: sy + 8, w: 8, h: 7 } },
      ];

      local panel_cache(sy) = [
        row.new('Cache') + { gridPos: { x: 0, y: sy, w: 24, h: 1 } },
        cache_size { gridPos: { x: 0, y: sy + 1, w: 12, h: 7 } },
        cache_fetched_keys { gridPos: { x: 12, y: sy + 1, w: 12, h: 7 } },
        cache_hits_keys { gridPos: { x: 0, y: sy + 8, w: 12, h: 7 } },
      ];

      local panel_querrier(sy) = [
        row.new('Querier') + { gridPos: { x: 0, y: sy, w: 24, h: 1 } },
        querier_cache_hits { gridPos: { x: 0, y: sy + 1, w: 8, h: 7 } },
        querier_cache_puts { gridPos: { x: 8, y: sy + 1, w: 8, h: 7 } },
        querier_cache_gets { gridPos: { x: 16, y: sy + 1, w: 8, h: 7 } },
        querier_cache_corruptions { gridPos: { x: 0, y: sy + 8, w: 12, h: 7 } },
        querier_cache_errors { gridPos: { x: 12, y: sy + 8, w: 12, h: 7 } },
      ];

      local panel_overview = [
        row.new('Overview') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        version { gridPos: { x: 0, y: 1, w: 4, h: 5 } },
        msgs { gridPos: { x: 4, y: 1, w: 4, h: 5 } },
        errors { gridPos: { x: 8, y: 1, w: 4, h: 5 } },
        panic { gridPos: { x: 12, y: 1, w: 4, h: 5 } },
      ];

      local panels =
        panel_overview
        + panel_msgs(6)
        + panel_api(14)
        + panel_cache(29)
        + panel_querrier(44)
        + panel_ingester(59);

      dashboard.new('Loki Distributed')
      + dashboard.withUid($._config.grafanaDashboards.ids.lokiDistributed)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(loki_build_info{cluster="$cluster"}, job)'),
      ])
      + dashboard.withPanels(panels),
  },
}
