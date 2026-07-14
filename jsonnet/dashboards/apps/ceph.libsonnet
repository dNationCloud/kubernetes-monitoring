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

/* K8s ceph dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local gaugePanel = grafana.panel.gauge;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;
local fieldOverride = grafana.panel.timeSeries.fieldOverride;

{
  grafanaDashboards+:: {
    ceph:
      local color = $._config.grafanaDashboards.color;

      local promTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local statBase(title, expr, unit='none', decimals=null, reducer='lastNotNull', steps=[], cmode='value', mappings=null) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit(unit)
        + (if decimals != null then statPanel.standardOptions.withDecimals(decimals) else {})
        + statPanel.options.withColorMode(cmode)
        + statPanel.options.withGraphMode('none')
        + statPanel.options.reduceOptions.withCalcs([reducer])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps(steps)
        + (if mappings != null then statPanel.standardOptions.withMappings(mappings) else {})
        + statPanel.queryOptions.withTargets([promTarget(expr, if title == 'Cluster Health' then 'Health' else null)]);

      local clusterHealth = statBase('Cluster Health',
                                     'ceph_health_status{cluster="$cluster"}',
                                     steps=[{ color: color.green, value: null }, { color: color.orange, value: 1 }, { color: color.red, value: 2 }],
                                     mappings=[{ type: 'value', options: { '0': { text: 'HEALTHY' }, '1': { text: 'WARNING' }, '2': { text: 'ERROR' } } }]);

      local writeThroughput = statBase('Write Throughput', 'sum(irate(ceph_osd_op_w_in_bytes{cluster="$cluster"}[5m]))', 'Bps', 1);
      local readThroughput = statBase('Read Throughput', 'sum(irate(ceph_osd_op_r_out_bytes{cluster="$cluster"}[5m]))', 'Bps', 1);
      local clusterCapacity = statBase('Cluster Capacity', 'ceph_cluster_total_bytes{cluster="$cluster"}', 'decbytes', 2);
      local writeIOPS = statBase('Write IOPS', 'sum(irate(ceph_osd_op_w{cluster="$cluster"}[5m]))', 'ops', 0);
      local readIOPS = statBase('Read IOPS', 'sum(irate(ceph_osd_op_r{cluster="$cluster"}[5m]))', 'ops', 0);
      local numObjects = statBase('Number of Objects', 'sum(ceph_pool_objects{cluster="$cluster"})', 'short', 2);
      local bytesWritten = statBase('Bytes Written', 'ceph_cluster_total_used_bytes{cluster="$cluster"}', 'decbytes', 1, 'delta');
      local bytesRead = statBase('Bytes Read', 'sum(ceph_osd_op_r_out_bytes{cluster="$cluster"})', 'decbytes', 1, 'delta');
      local difference = statBase('Difference', 'sum(ceph_pool_objects)', 'short', 2, 'diff');

      local monSessionNum = statBase('Mon Session Num',
                                     'sum(ceph_mon_num_sessions{cluster="$cluster"})',
                                     'short',
                                     0,
                                     steps=[{ color: color.green, value: null }, { color: color.red, value: 128 }]);

      local monitorsInQuorum = statBase('Monitors in Quorum',
                                        'count(ceph_mon_quorum_status{cluster="$cluster"}) or vector(0)',
                                        'none',
                                        0,
                                        cmode='background',
                                        steps=[{ color: color.red, value: null }, { color: color.orange, value: 2 }, { color: color.green, value: 3 }]);

      local usedCapacity = statBase('Used Capacity', 'ceph_cluster_total_used_bytes{cluster="$cluster"}', 'decbytes', 2);

      local osdOut = statBase('OSDs OUT',
                              'count(ceph_osd_up{cluster="$cluster"}) - count(ceph_osd_in{cluster="$cluster"})',
                              'none',
                              0,
                              steps=[{ color: color.green, value: null }, { color: color.red, value: 1 }]);

      local osdDown = statBase('OSDs DOWN',
                               'count(ceph_osd_up{cluster="$cluster"} == 0.0) OR vector(0)',
                               'none',
                               0,
                               steps=[{ color: color.green, value: null }, { color: color.red, value: 1 }]);

      local osdUP = statBase('OSDs UP',
                             'sum(ceph_osd_up{cluster="$cluster"})',
                             'none',
                             0,
                             steps=[{ color: color.green, value: null }, { color: color.red, value: 80 }]);

      local osdIN = statBase('OSDs IN',
                             'sum(ceph_osd_in{cluster="$cluster"})',
                             'none',
                             0,
                             steps=[{ color: color.green, value: null }, { color: color.red, value: 80 }]);

      local avgPGs = statBase('Avg PGs',
                              'sum(ceph_osd_numpg{cluster="$cluster"})',
                              'none',
                              1,
                              steps=[{ color: color.green, value: null }, { color: color.orange, value: 250 }, { color: color.red, value: 300 }]);

      local avgApplyLatency = statBase('Avg Apply Latency',
                                       'avg(ceph_osd_apply_latency_ms{cluster="$cluster"})',
                                       'ms',
                                       2,
                                       steps=[{ color: color.green, value: null }, { color: color.orange, value: 10 }, { color: color.red, value: 50 }]);

      local avgCommitLatency = statBase('Avg Commit Latency',
                                        'avg(ceph_osd_commit_latency_ms{cluster="$cluster"})',
                                        'ms',
                                        2,
                                        steps=[{ color: color.green, value: null }, { color: color.orange, value: 10 }, { color: color.red, value: 50 }]);

      local avgOPWriteLatency = statBase('Avg OP Write Latency',
                                         'clamp_min(avg(rate(ceph_osd_op_w_latency_sum{cluster="$cluster"}[5m]) / clamp_min(rate(ceph_osd_op_w_latency_count{cluster="$cluster"}[5m]), 1)), 0) or vector(0)',
                                         'ms',
                                         4,
                                         steps=[{ color: color.green, value: null }, { color: color.orange, value: 1 }, { color: color.red, value: 2 }]);

      local avgOPReadLatency = statBase('Avg OP Read Latency',
                                        'clamp_min(avg(rate(ceph_osd_op_r_latency_sum{cluster="$cluster"}[5m]) / clamp_min(rate(ceph_osd_op_r_latency_count{cluster="$cluster"}[5m]), 1)), 0) or vector(0)',
                                        'ms',
                                        4,
                                        steps=[{ color: color.green, value: null }, { color: color.orange, value: 1 }, { color: color.red, value: 2 }]);

      local availableCapacity =
        gaugePanel.new('Available Capacity')
        + gaugePanel.queryOptions.withDatasource('prometheus', '$datasource')
        + gaugePanel.standardOptions.withUnit('percentunit')
        + gaugePanel.standardOptions.withMin(0)
        + gaugePanel.standardOptions.withMax(1)
        + gaugePanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + gaugePanel.standardOptions.thresholds.withMode('absolute')
        + gaugePanel.standardOptions.thresholds.withSteps([{ color: color.red, value: null }, { color: color.orange, value: 0.1 }, { color: color.green, value: 0.3 }])
        + gaugePanel.queryOptions.withTargets([promTarget('(ceph_cluster_total_bytes{cluster="$cluster"} - ceph_cluster_total_used_bytes{cluster="$cluster"}) / ceph_cluster_total_bytes{cluster="$cluster"}')]);

      local legendTableFull =
        timeSeriesPanel.options.legend.withDisplayMode('table') + timeSeriesPanel.options.legend.withPlacement('bottom')
        + timeSeriesPanel.options.legend.withCalcs(['mean', 'lastNotNull', 'max', 'min']);

      local timeSeriesBase(title, unit, fillOpacity, decimals, min=null, stack=false, legend=null, overrides=[]) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit(unit)
        + timeSeriesPanel.standardOptions.withDecimals(decimals)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(fillOpacity)
        + (if min != null then timeSeriesPanel.standardOptions.withMin(min) else {})
        + (if stack then timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' }) else {})
        + (if std.length(overrides) > 0 then timeSeriesPanel.standardOptions.withOverrides(overrides) else {})
        + (if legend != null then legend else {})
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc');

      local capacityPanel =
        timeSeriesBase('Capacity', 'bytes', 50, 2, min=0, stack=true, legend=legendTableFull, overrides=[
          fieldOverride.byName.new('Available')
            + fieldOverride.byName.withProperty('color', { mode: 'fixed', fixedColor: color.orange }),
          fieldOverride.byName.new('Used')
            + fieldOverride.byName.withProperty('color', { mode: 'fixed', fixedColor: color.red }),
          fieldOverride.byName.new('Total Capacity')
            + fieldOverride.byName.withProperty('color', { mode: 'fixed', fixedColor: color.blue })
            + fieldOverride.byName.withProperty('custom.fillOpacity', 0)
            + fieldOverride.byName.withProperty('custom.stacking', { mode: 'none' })
            + fieldOverride.byName.withProperty('custom.lineWidth', 3),
        ])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('ceph_cluster_total_bytes{cluster="$cluster"} - ceph_cluster_total_used_bytes{cluster="$cluster"}', 'Available'),
          promTarget('ceph_cluster_total_used_bytes{cluster="$cluster"}', 'Used'),
          promTarget('ceph_cluster_total_bytes{cluster="$cluster"}', 'Total Capacity'),
        ]);

      local wrReadOverrides = [
        fieldOverride.byName.new('Write')
          + fieldOverride.byName.withProperty('color', { mode: 'fixed', fixedColor: color.red })
          + fieldOverride.byName.withProperty('custom.fillOpacity', 60)
          + fieldOverride.byName.withProperty('custom.lineWidth', 1),
        fieldOverride.byName.new('Read')
          + fieldOverride.byName.withProperty('color', { mode: 'fixed', fixedColor: color.blue })
          + fieldOverride.byName.withProperty('custom.fillOpacity', 60)
          + fieldOverride.byName.withProperty('custom.lineWidth', 1),
      ];

      local iopsPanel =
        timeSeriesBase('IOPS', 'iops', 50, 0, min=0, stack=true, legend=legendTableFull, overrides=wrReadOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(ceph_osd_op_w{cluster="$cluster"}[5m]))', 'Write'),
          promTarget('sum(irate(ceph_osd_op_r{cluster="$cluster"}[5m]))', 'Read'),
        ]);

      local clusterThroughputPanel =
        timeSeriesBase('Cluster Throughput', 'decbytes', 50, 1, min=0, stack=true, legend=legendTableFull, overrides=wrReadOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(ceph_osd_op_w_in_bytes{cluster="$cluster"}[5m]))', 'Write'),
          promTarget('sum(irate(ceph_osd_op_r_out_bytes{cluster="$cluster"}[5m]))', 'Read'),
        ]);

      local poolUsedBytesPanel =
        timeSeriesBase('Pool Used Bytes', 'bytes', 10, 2)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('(ceph_pool_bytes_used{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})', '{{name}}')]);

      local poolRawBytesPanel =
        timeSeriesBase('Pool RAW Bytes', 'bytes', 10, 2, min=0, legend=timeSeriesPanel.options.legend.withDisplayMode('table') + timeSeriesPanel.options.legend.withPlacement('right') + timeSeriesPanel.options.legend.withCalcs(['lastNotNull']))
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('(ceph_pool_avail_raw{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})', '{{name}} Avail'),
          promTarget('(ceph_pool_stored_raw{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})', '{{name}} Stored'),
        ]);

      local objectsPerPoolPanel =
        timeSeriesBase('Objects Per Pool', 'short', 10, 0, min=0, legend=timeSeriesPanel.options.legend.withPlacement('right'))
        + timeSeriesPanel.queryOptions.withTargets([promTarget('(ceph_pool_objects{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})', '{{name}}')]);

      local poolQuotaBytesPanel =
        timeSeriesBase('Pool Quota Bytes', 'bytes', 10, 2, min=0)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('(ceph_pool_quota_bytes{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})', '{{name}}')]);

      local poolObjectsQuotaPanel =
        timeSeriesBase('Pool Objects Quota', 'short', 10, 0, min=0)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('(ceph_pool_quota_objects{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})', '{{name}}')]);

      local osdTypeCountPanel =
        timeSeriesBase('OSD Type Count', 'short', 10, 0, min=0, legend=timeSeriesPanel.options.legend.withCalcs(['lastNotNull']))
        + timeSeriesPanel.queryOptions.withTargets([promTarget('count(ceph_bluestore_kv_commit_lat_count{cluster="$cluster"})', 'BlueStore')]);

      local panels = [
        row.new('CLUSTER STATE') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        clusterHealth { gridPos: { x: 0, y: 1, w: 3, h: 6 } },
        writeThroughput { gridPos: { x: 3, y: 1, w: 3, h: 3 } },
        readThroughput { gridPos: { x: 6, y: 1, w: 3, h: 3 } },
        clusterCapacity { gridPos: { x: 9, y: 1, w: 3, h: 3 } },
        availableCapacity { gridPos: { x: 12, y: 1, w: 3, h: 6 } },
        writeIOPS { gridPos: { x: 3, y: 4, w: 3, h: 3 } },
        readIOPS { gridPos: { x: 6, y: 4, w: 3, h: 3 } },
        usedCapacity { gridPos: { x: 9, y: 4, w: 3, h: 3 } },
        numObjects { gridPos: { x: 15, y: 1, w: 3, h: 3 } },
        bytesWritten { gridPos: { x: 18, y: 1, w: 3, h: 3 } },
        bytesRead { gridPos: { x: 21, y: 1, w: 3, h: 3 } },
        difference { gridPos: { x: 15, y: 4, w: 3, h: 3 } },
        monSessionNum { gridPos: { x: 18, y: 4, w: 3, h: 3 } },
        monitorsInQuorum { gridPos: { x: 21, y: 4, w: 3, h: 3 } },
        row.new('OSD STATE') + { gridPos: { x: 0, y: 7, w: 24, h: 1 } },
        osdOut { gridPos: { x: 0, y: 8, w: 3, h: 3 } },
        osdDown { gridPos: { x: 3, y: 8, w: 3, h: 3 } },
        osdUP { gridPos: { x: 6, y: 8, w: 3, h: 3 } },
        osdIN { gridPos: { x: 9, y: 8, w: 3, h: 3 } },
        avgPGs { gridPos: { x: 12, y: 8, w: 3, h: 3 } },
        avgApplyLatency { gridPos: { x: 15, y: 8, w: 3, h: 3 } },
        avgCommitLatency { gridPos: { x: 18, y: 8, w: 2, h: 3 } },
        avgOPWriteLatency { gridPos: { x: 20, y: 8, w: 2, h: 3 } },
        avgOPReadLatency { gridPos: { x: 22, y: 8, w: 2, h: 3 } },
        row.new('CLUSTER STATS') + { gridPos: { x: 0, y: 11, w: 24, h: 1 } },
        capacityPanel { gridPos: { x: 0, y: 12, w: 8, h: 8 } },
        iopsPanel { gridPos: { x: 8, y: 12, w: 8, h: 8 } },
        clusterThroughputPanel { gridPos: { x: 16, y: 12, w: 8, h: 8 } },
        poolUsedBytesPanel { gridPos: { x: 0, y: 20, w: 8, h: 8 } },
        poolRawBytesPanel { gridPos: { x: 8, y: 20, w: 8, h: 8 } },
        objectsPerPoolPanel { gridPos: { x: 16, y: 20, w: 8, h: 8 } },
        poolQuotaBytesPanel { gridPos: { x: 0, y: 28, w: 8, h: 8 } },
        poolObjectsQuotaPanel { gridPos: { x: 8, y: 28, w: 8, h: 8 } },
        osdTypeCountPanel { gridPos: { x: 16, y: 28, w: 8, h: 8 } },
      ];

      dashboard.new('Ceph Cluster Overview')
      + dashboard.withUid($._config.grafanaDashboards.ids.ceph)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
      ])
      + dashboard.withPanels(panels),
  },
}
