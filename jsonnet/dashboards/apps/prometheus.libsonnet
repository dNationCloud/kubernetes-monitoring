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

/* Prometheus dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    prometheus:
      local color = $._config.grafanaDashboards.color;

      local promTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr) + (if legendFormat != null && legendFormat != '' then prometheus.withLegendFormat(legendFormat) else {});

      local statBase(title, expr, steps, unit='none', decimals=null, graphMode='none', colorMode='value', legend=null) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit(unit)
        + (if decimals != null then statPanel.standardOptions.withDecimals(decimals) else {})
        + statPanel.options.withColorMode(colorMode)
        + statPanel.options.withGraphMode(graphMode)
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps(steps)
        + statPanel.standardOptions.withMappings([{ type: 'special', options: { match: 'null', result: { text: 'N/A' } } }])
        + statPanel.queryOptions.withTargets([promTarget(expr, legend)]);

      local upTime = statBase('Uptime [$interval]',
                              'avg(avg_over_time(up{instance=~"$instance",job=~"$job"}[$interval]) * 100)',
                              [{ color: color.red, value: null }, { color: color.orange, value: 90 }, { color: color.green, value: 99 }],
                              'percent',
                              3);

      local totalSeries = statBase('Total Series',
                                   'sum(prometheus_tsdb_head_series{job=~"$job",instance=~"$instance"})',
                                   [{ color: color.green, value: null }, { color: color.orange, value: 1000000 }, { color: color.red, value: 2000000 }],
                                   graphMode='area');

      local memoryChunks = statBase('Memory Chunks',
                                    'sum(prometheus_tsdb_head_chunks{job=~"$job",instance=~"$instance"})',
                                    [{ color: color.green, value: null }],
                                    graphMode='area',
                                    colorMode='none');

      local itrSteps = [{ color: color.green, value: null }, { color: color.orange, value: 1 }, { color: color.red, value: 10 }];
      local missedItr = statBase('Missed Iterations [$interval]', 'sum(sum_over_time(prometheus_evaluator_iterations_missed_total{job=~"$job",instance=~"$instance"}[$interval]))', itrSteps);
      local skippedItr = statBase('Skipped Iterations [$interval]', 'sum(sum_over_time(prometheus_evaluator_iterations_skipped_total{job=~"$job",instance=~"$instance"}[$interval]))', itrSteps, legend='time_series');
      local tardyScp = statBase('Tardy Scrapes [$interval]', 'sum(sum_over_time(prometheus_target_scrapes_exceeded_sample_limit_total{job=~"$job",instance=~"$instance"}[$interval]))', itrSteps);
      local reloadFailures = statBase('Reload Failures [$interval]', 'sum(sum_over_time(prometheus_tsdb_reloads_failures_total{job=~"$job",instance=~"$instance"}[$interval]))', itrSteps, legend='time_series');
      local skippedScrapes = statBase('Skipped Scrapes [$interval]', 'sum(sum_over_time(prometheus_target_scrapes_exceeded_sample_limit_total{job=~"$job",instance=~"$instance"}[$interval])) + sum(sum_over_time(prometheus_target_scrapes_sample_duplicate_timestamp_total{job=~"$job",instance=~"$instance"}[$interval])) + sum(sum_over_time(prometheus_target_scrapes_sample_out_of_bounds_total{job=~"$job",instance=~"$instance"}[$interval])) + sum(sum_over_time(prometheus_target_scrapes_sample_out_of_order_total{job=~"$job",instance=~"$instance"}[$interval])) ', itrSteps);

      local timeSeriesBase(title, labelY1=null, unit=null, min=null, stack=false) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + (if labelY1 != null then timeSeriesPanel.fieldConfig.defaults.custom.withAxisLabel(labelY1) else {})
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + (if min != null then timeSeriesPanel.standardOptions.withMin(min) else {})
        + (if stack then timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' }) else {})
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc');

      local failuresErrors =
        timeSeriesBase('Failures and Errors', 'Errors')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(increase(net_conntrack_dialer_conn_failed_total{instance=~"$instance"}[5m])) > 0', 'Failed Connections'),
          promTarget('sum(increase(prometheus_evaluator_iterations_missed_total{instance=~"$instance"}[5m])) > 0', 'Missed Iterations'),
          promTarget('sum(increase(prometheus_evaluator_iterations_skipped_total{instance=~"$instance"}[5m])) > 0', 'Skipped Iterations'),
          promTarget('sum(increase(prometheus_rule_evaluation_failures_total{instance=~"$instance"}[5m])) > 0', 'Evaluation'),
          promTarget('sum(increase(prometheus_sd_azure_refresh_failures_total{instance=~"$instance"}[5m])) > 0', 'Azure Refresh'),
          promTarget('sum(increase(prometheus_sd_consul_rpc_failures_total{instance=~"$instance"}[5m])) > 0', 'Consul RPC'),
          promTarget('sum(increase(prometheus_sd_dns_lookup_failures_total{instance=~"$instance"}[5m])) > 0', 'DNS Lookup'),
          promTarget('sum(increase(prometheus_sd_ec2_refresh_failures_total{instance=~"$instance"}[5m])) > 0', 'EC2 Refresh'),
          promTarget('sum(increase(prometheus_sd_gce_refresh_failures_total{instance=~"$instance"}[5m])) > 0', 'GCE Refresh'),
          promTarget('sum(increase(prometheus_sd_marathon_refresh_failures_total{instance=~"$instance"}[5m])) > 0', 'Marathon Refresh'),
          promTarget('sum(increase(prometheus_sd_marathon_refresh_failures_total{instance=~"$instance"}[5m])) > 0', 'Openstack Refresh'),
          promTarget('sum(increase(prometheus_sd_triton_refresh_failures_total{instance=~"$instance"}[5m])) > 0', 'Triton Refresh'),
          promTarget('sum(increase(prometheus_target_scrapes_exceeded_sample_limit_total{instance=~"$instance"}[5m])) > 0', 'Sample Limit'),
          promTarget('sum(increase(prometheus_target_scrapes_sample_duplicate_timestamp_total{instance=~"$instance"}[5m])) > 0', 'Duplicate Timestamp'),
          promTarget('sum(increase(prometheus_target_scrapes_sample_out_of_bounds_total{instance=~"$instance"}[5m])) > 0', 'Timestamp Out of Bounds'),
          promTarget('sum(increase(prometheus_target_scrapes_sample_out_of_order_total{instance=~"$instance"}[5m])) > 0', 'Sample Out of Order'),
          promTarget('sum(increase(prometheus_treecache_zookeeper_failures_total{instance=~"$instance"}[5m])) > 0', 'Zookeeper'),
          promTarget('sum(increase(prometheus_tsdb_compactions_failed_total{instance=~"$instance"}[5m])) > 0', 'TSDB Compactions'),
          promTarget('sum(increase(prometheus_tsdb_head_series_not_found{instance=~"$instance"}[5m])) > 0', 'Series Not Found'),
          promTarget('sum(increase(prometheus_tsdb_reloads_failures_total{instance=~"$instance"}[5m])) > 0', 'Reload'),
        ]);

      local upness = timeSeriesBase('Upness (stacked)', 'Up', min=0, stack=true)
                     + timeSeriesPanel.queryOptions.withTargets([promTarget('up{instance=~"$instance",job=~"$job"}', '{{instance}}')]);

      local storMemChunks = timeSeriesBase('Storage Memory Chunks', 'Chunks', min=0)
                            + timeSeriesPanel.queryOptions.withTargets([promTarget('prometheus_tsdb_head_chunks{job=~"$job",instance=~"$instance"}', '{{instance}}')]);

      local seriesCount = timeSeriesBase('Series Count', 'Series', min=0)
                          + timeSeriesPanel.queryOptions.withTargets([promTarget('prometheus_tsdb_head_series{job=~"$job",instance=~"$instance"}', '{{instance}}')]);

      local seriesCreated = timeSeriesBase('Series Created / Removed', 'Series Count', min=0)
                            + timeSeriesPanel.queryOptions.withTargets([
                              promTarget('sum( increase(prometheus_tsdb_head_series_created_total{instance=~"$instance"}[5m]) )', 'created'),
                              promTarget('sum( increase(prometheus_tsdb_head_series_removed_total{instance=~"$instance"}[5m]) )', 'removed'),
                            ]);

      local sampleSecond = timeSeriesBase('Appended Samples per Second', 'Samples / Second', min=0)
                           + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(prometheus_tsdb_head_samples_appended_total{job=~"$job",instance=~"$instance"}[1m])', '{{instance}}')]);

      local scrapeSync = timeSeriesBase('Scrape Sync Total', 'Syncs', min=0)
                         + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(prometheus_target_scrape_pool_sync_total{job=~"$job",instance=~"$instance"}) by (scrape_job)', '{{scrape_job}}')]);

      local targetSync = timeSeriesBase('Target Sync', 'Milliseconds', min=0)
                         + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(prometheus_target_sync_length_seconds_sum{job=~"$job",instance=~"$instance"}[2m])) by (scrape_job) * 1000', '{{scrape_job}}')]);

      local scrapeDur = timeSeriesBase('Scrape Duration', 'Seconds', min=0)
                        + timeSeriesPanel.queryOptions.withTargets([promTarget('scrape_duration_seconds{instance=~"$instance"}', '{{instance}}')]);

      local scrapeRej = timeSeriesBase('Rejected Scrapes', 'Scrapes', min=0)
                        + timeSeriesPanel.queryOptions.withTargets([
                          promTarget('sum(prometheus_target_scrapes_exceeded_sample_limit_total{job=~"$job",instance=~"$instance"})', 'exceeded sample limit'),
                          promTarget('sum(prometheus_target_scrapes_sample_duplicate_timestamp_total{job=~"$job",instance=~"$instance"})', 'exceeded sample limit'),
                          promTarget('sum(prometheus_target_scrapes_sample_out_of_bounds_total{job=~"$job",instance=~"$instance"})', 'out of bounds'),
                          promTarget('sum(prometheus_target_scrapes_sample_out_of_order_total{job=~"$job",instance=~"$instance"})  ', 'out of order'),
                        ]);

      local engQueDur = timeSeriesBase('Prometheus Engine Query Duration Seconds', 'Seconds', min=0)
                        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(prometheus_engine_query_duration_seconds_sum{job=~"$job",instance=~"$instance"}) by (slice)', '{{slice}}')]);

      local notSent = timeSeriesBase('Notifications Sent', 'Notifications', min=0)
                      + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(prometheus_notifications_sent_total[5m])', '{{instance}}')]);

      local minConf = timeSeriesBase('Minutes Since Successful Config Reload', 'Minutes', min=0)
                      + timeSeriesPanel.queryOptions.withTargets([promTarget('(time() - prometheus_config_last_reload_success_timestamp_seconds{job=~"$job",instance=~"$instance"}) / 60', '{{instance}}')]);

      local succConf = timeSeriesBase('Successful Config Reload', 'Success', min=0)
                       + timeSeriesPanel.queryOptions.withTargets([promTarget('prometheus_config_last_reload_successful{job=~"$job",instance=~"$instance"}', '{{instance}}')]);

      local gcRate = timeSeriesBase('GC Rate / 2m')
                     + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(go_gc_duration_seconds_sum{instance=~"$instance",job=~"$job"}[2m])) by (instance)', '{{instance}}')]);

      local appSampleRate = timeSeriesBase('Appended sample rate', 'New samples appended', min=0)
                            + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(prometheus_tsdb_head_samples_appended_total[$interval])', 'samples appended to db By sec')]);

      local retNeeded = timeSeriesBase('Retention Size needed', unit='bytes')
                        + timeSeriesPanel.queryOptions.withTargets([promTarget('$retention * (60*60*24) * rate(prometheus_tsdb_head_samples_appended_total[$interval]) * 2', 'Retention size needed')]);

      local panels = [
        row.new('Quick Info') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        upTime { gridPos: { x: 0, y: 1, w: 8, h: 3 } },
        totalSeries { gridPos: { x: 8, y: 1, w: 8, h: 3 } },
        memoryChunks { gridPos: { x: 16, y: 1, w: 8, h: 3 } },
        row.new('Numbers') + { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
        missedItr { gridPos: { x: 0, y: 5, w: 5, h: 3 } },
        skippedItr { gridPos: { x: 5, y: 5, w: 5, h: 3 } },
        tardyScp { gridPos: { x: 10, y: 5, w: 5, h: 3 } },
        reloadFailures { gridPos: { x: 15, y: 5, w: 5, h: 3 } },
        skippedScrapes { gridPos: { x: 20, y: 5, w: 4, h: 3 } },
        row.new('Errors') + { gridPos: { x: 0, y: 9, w: 24, h: 1 } },
        failuresErrors { gridPos: { x: 0, y: 10, w: 24, h: 7 } },
        row.new('Up') + { gridPos: { x: 0, y: 17, w: 24, h: 1 } },
        upness { gridPos: { x: 0, y: 18, w: 12, h: 7 } },
        storMemChunks { gridPos: { x: 12, y: 18, w: 12, h: 7 } },
        row.new('Series') + { gridPos: { x: 0, y: 25, w: 24, h: 1 } },
        seriesCount { gridPos: { x: 0, y: 26, w: 12, h: 7 } },
        seriesCreated { gridPos: { x: 12, y: 26, w: 12, h: 7 } },
        row.new('Appended Samples') + { gridPos: { x: 0, y: 33, w: 24, h: 1 } },
        sampleSecond { gridPos: { x: 0, y: 34, w: 24, h: 7 } },
        row.new('Sync') + { gridPos: { x: 0, y: 41, w: 24, h: 1 } },
        scrapeSync { gridPos: { x: 0, y: 42, w: 12, h: 7 } },
        targetSync { gridPos: { x: 12, y: 42, w: 12, h: 7 } },
        row.new('Scrapes') + { gridPos: { x: 0, y: 49, w: 24, h: 1 } },
        scrapeDur { gridPos: { x: 0, y: 50, w: 12, h: 7 } },
        scrapeRej { gridPos: { x: 12, y: 50, w: 12, h: 7 } },
        row.new('Durations') + { gridPos: { x: 0, y: 57, w: 24, h: 1 } },
        engQueDur { gridPos: { x: 0, y: 58, w: 24, h: 7 } },
        row.new('Notifications') + { gridPos: { x: 0, y: 65, w: 24, h: 1 } },
        notSent { gridPos: { x: 0, y: 66, w: 24, h: 7 } },
        row.new('Config') + { gridPos: { x: 0, y: 73, w: 24, h: 1 } },
        minConf { gridPos: { x: 0, y: 74, w: 8, h: 7 } },
        succConf { gridPos: { x: 8, y: 74, w: 8, h: 7 } },
        gcRate { gridPos: { x: 16, y: 74, w: 8, h: 7 } },
        row.new('Retention') + { gridPos: { x: 0, y: 81, w: 24, h: 1 } },
        appSampleRate { gridPos: { x: 0, y: 82, w: 12, h: 7 } },
        retNeeded { gridPos: { x: 12, y: 82, w: 12, h: 7 } },
      ];

      dashboard.new('Prometheus')
      + dashboard.withUid($._config.grafanaDashboards.ids.prometheus)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sVMs)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.intervalTemplate('1h, 3h, 6h, 12h, 1d, 2d, 7d, 30d, 90d, 180d'),
        $.grafanaTemplates.jobTemplate('query_result(prometheus_tsdb_head_samples_appended_total)', regex='/.*job="([^"]+)/'),
        $.grafanaTemplates.instanceTemplate('query_result(up{job=~"$job"})', regex='/.*instance="([^"]+).*/'),
        $.grafanaTemplates.retentionTemplate(),
      ])
      + dashboard.withPanels(panels),
  },
}
