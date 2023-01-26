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
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local singlestat = grafana.singlestat;

{
  grafanaDashboards+:: {
    prometheus:
      local upTime =
        singlestat.new(
          title='Uptime [$interval]',
          datasource='$datasource',
          valueName='current',
          colorValue=true,
          thresholds='90,99',
          colors=[$._config.grafanaDashboards.color.red, $._config.grafanaDashboards.color.orange, $._config.grafanaDashboards.color.green],
          decimals=3,
          format='percent',
          rangeMaps=[
            {
              from: 'null',
              text: 'N/A',
              to: 'null',
            },
          ],
        )
        .addTarget(prometheus.target('avg(avg_over_time(up{instance=~"$instance",job=~"$job"}[$interval]) * 100)', legendFormat=''));

      local totalSeries =
        singlestat.new(
          title='Total Series',
          datasource='$datasource',
          colorValue=true,
          thresholds='1000000,2000000',
          valueName='current',
          sparklineShow=true,
          rangeMaps=[
            {
              from: 'null',
              text: 'N/A',
              to: 'null',
            },
          ],
        )
        .addTarget(prometheus.target('sum(prometheus_tsdb_head_series{job=~"$job",instance=~"$instance"})', legendFormat=''));

      local memoryChunks =
        singlestat.new(
          title='Memory Chunks',
          datasource='$datasource',
          valueName='current',
          sparklineShow=true,
          rangeMaps=[
            {
              from: 'null',
              text: 'N/A',
              to: 'null',
            },
          ],
        )
        .addTarget(prometheus.target('sum(prometheus_tsdb_head_chunks{job=~"$job",instance=~"$instance"})', legendFormat=''));

      local missedItr =
        singlestat.new(
          title='Missed Iterations [$interval]',
          datasource='$datasource',
          colorValue=true,
          valueName='current',
          thresholds='1,10',
          rangeMaps=[
            {
              from: 'null',
              text: 'N/A',
              to: 'null',
            },
          ],
        )
        .addTarget(prometheus.target('sum(sum_over_time(prometheus_evaluator_iterations_missed_total{job=~"$job",instance=~"$instance"}[$interval]))', legendFormat=''));

      local skippedItr =
        singlestat.new(
          title='Skipped Iterations [$interval]',
          datasource='$datasource',
          colorValue=true,
          valueName='current',
          thresholds='1,10',
          rangeMaps=[
            {
              from: 'null',
              text: 'N/A',
              to: 'null',
            },
          ],
        )
        .addTarget(prometheus.target('sum(sum_over_time(prometheus_evaluator_iterations_skipped_total{job=~"$job",instance=~"$instance"}[$interval]))', legendFormat='time_series'),);

      local tardyScp =
        singlestat.new(
          title='Tardy Scrapes [$interval]',
          datasource='$datasource',
          colorValue=true,
          valueName='current',
          thresholds='1,10',
          rangeMaps=[
            {
              from: 'null',
              text: 'N/A',
              to: 'null',
            },
          ],
        )
        .addTarget(prometheus.target('sum(sum_over_time(prometheus_target_scrapes_exceeded_sample_limit_total{job=~"$job",instance=~"$instance"}[$interval]))', legendFormat=''));

      local reloadFailures =
        singlestat.new(
          title='Reload Failures [$interval]',
          datasource='$datasource',
          colorValue=true,
          valueName='current',
          thresholds='1,10',
          rangeMaps=[
            {
              from: 'null',
              text: 'N/A',
              to: 'null',
            },
          ],
        )
        .addTarget(prometheus.target('sum(sum_over_time(prometheus_tsdb_reloads_failures_total{job=~"$job",instance=~"$instance"}[$interval]))', legendFormat='time_series'));

      local skippedScrapes =
        singlestat.new(
          title='Skipped Scrapes [$interval]',
          datasource='$datasource',
          colorValue=true,
          valueName='current',
          thresholds='1,10',
          rangeMaps=[
            {
              from: 'null',
              text: 'N/A',
              to: 'null',
            },
          ],
        )
        .addTarget(prometheus.target('sum(sum_over_time(prometheus_target_scrapes_exceeded_sample_limit_total{job=~"$job",instance=~"$instance"}[$interval])) + sum(sum_over_time(prometheus_target_scrapes_sample_duplicate_timestamp_total{job=~"$job",instance=~"$instance"}[$interval])) + sum(sum_over_time(prometheus_target_scrapes_sample_out_of_bounds_total{job=~"$job",instance=~"$instance"}[$interval])) + sum(sum_over_time(prometheus_target_scrapes_sample_out_of_order_total{job=~"$job",instance=~"$instance"}[$interval])) ', legendFormat=''));

      local failuresErrors =
        graphPanel.new(
          title='Failures and Errors',
          datasource='$datasource',
          labelY1='Errors',
        )
        .addTargets(
          [
            prometheus.target('sum(increase(net_conntrack_dialer_conn_failed_total{instance=~"$instance"}[5m])) > 0', legendFormat='Failed Connections'),
            prometheus.target('sum(increase(prometheus_evaluator_iterations_missed_total{instance=~"$instance"}[5m])) > 0', legendFormat='Missed Iterations'),
            prometheus.target('sum(increase(prometheus_evaluator_iterations_skipped_total{instance=~"$instance"}[5m])) > 0', legendFormat='Skipped Iterations'),
            prometheus.target('sum(increase(prometheus_rule_evaluation_failures_total{instance=~"$instance"}[5m])) > 0', legendFormat='Evaluation'),
            prometheus.target('sum(increase(prometheus_sd_azure_refresh_failures_total{instance=~"$instance"}[5m])) > 0', legendFormat='Azure Refresh'),
            prometheus.target('sum(increase(prometheus_sd_consul_rpc_failures_total{instance=~"$instance"}[5m])) > 0', legendFormat='Consul RPC'),
            prometheus.target('sum(increase(prometheus_sd_dns_lookup_failures_total{instance=~"$instance"}[5m])) > 0', legendFormat='DNS Lookup'),
            prometheus.target('sum(increase(prometheus_sd_ec2_refresh_failures_total{instance=~"$instance"}[5m])) > 0', legendFormat='EC2 Refresh'),
            prometheus.target('sum(increase(prometheus_sd_gce_refresh_failures_total{instance=~"$instance"}[5m])) > 0', legendFormat='GCE Refresh'),
            prometheus.target('sum(increase(prometheus_sd_marathon_refresh_failures_total{instance=~"$instance"}[5m])) > 0', legendFormat='Marathon Refresh'),
            prometheus.target('sum(increase(prometheus_sd_marathon_refresh_failures_total{instance=~"$instance"}[5m])) > 0', legendFormat='Openstack Refresh'),
            prometheus.target('sum(increase(prometheus_sd_triton_refresh_failures_total{instance=~"$instance"}[5m])) > 0', legendFormat='Triton Refresh'),
            prometheus.target('sum(increase(prometheus_target_scrapes_exceeded_sample_limit_total{instance=~"$instance"}[5m])) > 0', legendFormat='Sample Limit'),
            prometheus.target('sum(increase(prometheus_target_scrapes_sample_duplicate_timestamp_total{instance=~"$instance"}[5m])) > 0', legendFormat='Duplicate Timestamp'),
            prometheus.target('sum(increase(prometheus_target_scrapes_sample_out_of_bounds_total{instance=~"$instance"}[5m])) > 0', legendFormat='Timestamp Out of Bounds'),
            prometheus.target('sum(increase(prometheus_target_scrapes_sample_out_of_order_total{instance=~"$instance"}[5m])) > 0', legendFormat='Sample Out of Order'),
            prometheus.target('sum(increase(prometheus_treecache_zookeeper_failures_total{instance=~"$instance"}[5m])) > 0', legendFormat='Zookeeper'),
            prometheus.target('sum(increase(prometheus_tsdb_compactions_failed_total{instance=~"$instance"}[5m])) > 0', legendFormat='TSDB Compactions'),
            prometheus.target('sum(increase(prometheus_tsdb_head_series_not_found{instance=~"$instance"}[5m])) > 0', legendFormat='Series Not Found'),
            prometheus.target('sum(increase(prometheus_tsdb_reloads_failures_total{instance=~"$instance"}[5m])) > 0', legendFormat='Reload'),
          ],
        );

      local upness =
        graphPanel.new(
          title='Upness (stacked)',
          datasource='$datasource',
          min=0,
          labelY1='Up',
          stack=true,
        )
        .addTarget(prometheus.target('up{instance=~"$instance",job=~"$job"}', legendFormat='{{instance}}'));


      local storMemChunks =
        graphPanel.new(
          title='Storage Memory Chunks',
          datasource='$datasource',
          min=0,
          labelY1='Chunks',
        )
        .addTarget(prometheus.target('prometheus_tsdb_head_chunks{job=~"$job",instance=~"$instance"}', legendFormat='{{instance}}'));

      local seriesCount =
        graphPanel.new(
          title='Series Count',
          datasource='$datasource',
          min=0,
          labelY1='Series',
        )
        .addTarget(prometheus.target('prometheus_tsdb_head_series{job=~"$job",instance=~"$instance"}', legendFormat='{{instance}}'));

      local seriesCreated =
        graphPanel.new(
          title='Series Created / Removed',
          datasource='$datasource',
          min=0,
          labelY1='Series Count',
        )
        .addTargets(
          [
            prometheus.target('sum( increase(prometheus_tsdb_head_series_created_total{instance=~"$instance"}[5m]) )', legendFormat='created'),
            prometheus.target('sum( increase(prometheus_tsdb_head_series_removed_total{instance=~"$instance"}[5m]) )', legendFormat='removed'),
          ]
        );

      local sampleSecond =
        graphPanel.new(
          title='Appended Samples per Second',
          datasource='$datasource',
          min=0,
          labelY1='Samples / Second',
        )
        .addTarget(prometheus.target('rate(prometheus_tsdb_head_samples_appended_total{job=~"$job",instance=~"$instance"}[1m])', legendFormat='{{instance}}'));

      local scrapeSync =
        graphPanel.new(
          title='Scrape Sync Total',
          datasource='$datasource',
          min=0,
          labelY1='Syncs',
        )
        .addTarget(prometheus.target('sum(prometheus_target_scrape_pool_sync_total{job=~"$job",instance=~"$instance"}) by (scrape_job)', legendFormat='{{scrape_job}}'));

      local targetSync =
        graphPanel.new(
          title='Target Sync',
          datasource='$datasource',
          min=0,
          labelY1='Milliseconds',
        )
        .addTarget(prometheus.target('sum(rate(prometheus_target_sync_length_seconds_sum{job=~"$job",instance=~"$instance"}[2m])) by (scrape_job) * 1000', legendFormat='{{scrape_job}}'));

      local scrapeDur =
        graphPanel.new(
          title='Scrape Duration',
          datasource='$datasource',
          labelY1='Seconds',
          min=0,
        )
        .addTarget(prometheus.target('scrape_duration_seconds{instance=~"$instance"}', legendFormat='{{instance}}'));

      local scrapeRej =
        graphPanel.new(
          title='Rejected Scrapes',
          datasource='$datasource',
          labelY1='Scrapes',
          min=0,
        )
        .addTargets(
          [
            prometheus.target('sum(prometheus_target_scrapes_exceeded_sample_limit_total{job=~"$job",instance=~"$instance"})', legendFormat='exceeded sample limit'),
            prometheus.target('sum(prometheus_target_scrapes_sample_duplicate_timestamp_total{job=~"$job",instance=~"$instance"})', legendFormat='exceeded sample limit'),
            prometheus.target('sum(prometheus_target_scrapes_sample_out_of_bounds_total{job=~"$job",instance=~"$instance"})', legendFormat='out of bounds'),
            prometheus.target('sum(prometheus_target_scrapes_sample_out_of_order_total{job=~"$job",instance=~"$instance"})  ', legendFormat='out of order'),
          ]
        );

      local engQueDur =
        graphPanel.new(
          title='Prometheus Engine Query Duration Seconds',
          datasource='$datasource',
          min=0,
          labelY1='Seconds',
        )
        .addTarget(prometheus.target('sum(prometheus_engine_query_duration_seconds_sum{job=~"$job",instance=~"$instance"}) by (slice)', legendFormat='{{slice}}'));

      local notSent =
        graphPanel.new(
          title='Notifications Sent',
          datasource='$datasource',
          min=0,
          labelY1='Notifications',
        )
        .addTarget(prometheus.target('rate(prometheus_notifications_sent_total[5m])', legendFormat='{{instance}}'));

      local minConf =
        graphPanel.new(
          title='Minutes Since Successful Config Reload',
          datasource='$datasource',
          min=0,
          labelY1='Minutes',
        )
        .addTarget(prometheus.target('(time() - prometheus_config_last_reload_success_timestamp_seconds{job=~"$job",instance=~"$instance"}) / 60', legendFormat='{{instance}}'));

      local succConf =
        graphPanel.new(
          title='Successful Config Reload',
          datasource='$datasource',
          min=0,
          labelY1='Success',
        )
        .addTarget(prometheus.target('prometheus_config_last_reload_successful{job=~"$job",instance=~"$instance"}', legendFormat='{{instance}}'));

      local gcRate =
        graphPanel.new(
          title='GC Rate / 2m',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('sum(rate(go_gc_duration_seconds_sum{instance=~"$instance",job=~"$job"}[2m])) by (instance)', legendFormat='{{instance}}'));

      local appSampleRate =
        graphPanel.new(
          title='Appended sample rate',
          datasource='$datasource',
          labelY1='New samples appended',
          min=0,
        )
        .addTarget(prometheus.target('rate(prometheus_tsdb_head_samples_appended_total[$interval])', legendFormat='samples appended to db By sec'));

      local retNeeded =
        graphPanel.new(
          title='Retention Size needed',
          datasource='$datasource',
          formatY1='bytes'
        )
        .addTarget(prometheus.target('$retention * (60*60*24) * rate(prometheus_tsdb_head_samples_appended_total[$interval]) * 2', legendFormat='Retention size needed'));

      local panels = [
        row.new('Quick Info') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        upTime { gridPos: { x: 0, y: 1, w: 8, h: 3 } },
        totalSeries { gridPos: { x: 8, y: 1, w: 8, h: 3 } },
        memoryChunks { gridPos: { x: 16, y: 1, w: 8, h: 3 } },
        row.new('Numbers') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
        missedItr { gridPos: { x: 0, y: 5, w: 5, h: 3 } },
        skippedItr { gridPos: { x: 5, y: 5, w: 5, h: 3 } },
        tardyScp { gridPos: { x: 10, y: 5, w: 5, h: 3 } },
        reloadFailures { gridPos: { x: 15, y: 5, w: 5, h: 3 } },
        skippedScrapes { gridPos: { x: 20, y: 5, w: 4, h: 3 } },
        row.new('Errors') { gridPos: { x: 0, y: 9, w: 24, h: 1 } },
        failuresErrors { gridPos: { x: 0, y: 10, w: 24, h: 7 } },
        row.new('Up') { gridPos: { x: 0, y: 17, w: 24, h: 1 } },
        upness { gridPos: { x: 0, y: 18, w: 12, h: 7 } },
        storMemChunks { gridPos: { x: 12, y: 18, w: 12, h: 7 } },
        row.new('Series') { gridPos: { x: 0, y: 25, w: 24, h: 1 } },
        seriesCount { gridPos: { x: 0, y: 26, w: 12, h: 7 } },
        seriesCreated { gridPos: { x: 12, y: 26, w: 12, h: 7 } },
        row.new('Appended Samples') { gridPos: { x: 0, y: 33, w: 24, h: 1 } },
        sampleSecond { gridPos: { x: 0, y: 34, w: 24, h: 7 } },
        row.new('Sync') { gridPos: { x: 0, y: 41, w: 24, h: 1 } },
        scrapeSync { gridPos: { x: 0, y: 42, w: 12, h: 7 } },
        targetSync { gridPos: { x: 12, y: 42, w: 12, h: 7 } },
        row.new('Scrapes') { gridPos: { x: 0, y: 49, w: 24, h: 1 } },
        scrapeDur { gridPos: { x: 0, y: 50, w: 12, h: 7 } },
        scrapeRej { gridPos: { x: 12, y: 50, w: 12, h: 7 } },
        row.new('Durations') { gridPos: { x: 0, y: 57, w: 24, h: 1 } },
        engQueDur { gridPos: { x: 0, y: 58, w: 24, h: 7 } },
        row.new('Notifications') { gridPos: { x: 0, y: 65, w: 24, h: 1 } },
        notSent { gridPos: { x: 0, y: 66, w: 24, h: 7 } },
        row.new('Config') { gridPos: { x: 0, y: 73, w: 24, h: 1 } },
        minConf { gridPos: { x: 0, y: 74, w: 8, h: 7 } },
        succConf { gridPos: { x: 8, y: 74, w: 8, h: 7 } },
        gcRate { gridPos: { x: 16, y: 74, w: 8, h: 7 } },
        row.new('Retention') { gridPos: { x: 0, y: 81, w: 24, h: 1 } },
        appSampleRate { gridPos: { x: 0, y: 82, w: 12, h: 7 } },
        retNeeded { gridPos: { x: 12, y: 82, w: 12, h: 7 } },
      ];

      dashboard.new(
        'Prometheus',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sVMs,
        uid=$._config.grafanaDashboards.ids.prometheus,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.intervalTemplate('1h, 3h, 6h, 12h, 1d, 2d, 7d, 30d, 90d, 180d'),
        $.grafanaTemplates.jobTemplate('query_result(prometheus_tsdb_head_samples_appended_total)', regex='/.*job="([^"]+)/'),
        $.grafanaTemplates.instanceTemplate('query_result(up{job=~"$job"})', regex='/.*instance="([^"]+).*/'),
        $.grafanaTemplates.retentionTemplate(),
      ])
      .addPanels(panels),
  },
}
