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

/* K8s cadvisor dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local table = grafana.panel.table;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;
local fieldOverride = grafana.panel.timeSeries.fieldOverride;

{
  grafanaDashboards+:: {
    cadvisor:
      local promTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr)
        + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local tooltipSortDesc =
        timeSeriesPanel.options.tooltip.withMode('multi')
        + timeSeriesPanel.options.tooltip.withSort('desc');

      local timeSeriesStacked(title, unit) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit(unit)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + tooltipSortDesc;

      local rxTxOverrides = [
        fieldOverride.byRegexp.new('/Rx_/')
          + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'B' })
          + fieldOverride.byRegexp.withProperty('custom.transform', 'negative-Y'),
        fieldOverride.byRegexp.new('/Tx_/')
          + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'A' }),
      ];

      local containers =
        statPanel.new('Containers')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.options.withGraphMode('none')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds($._config.templates.L1.hostApps.genericApp.panel.thresholds))
        + statPanel.queryOptions.withTargets([
          promTarget('count(rate(container_last_seen{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m]))'),
        ]);

      local imageTable =
        table.new('')
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + table.standardOptions.withOverrides([
          fieldOverride.byName.new('Time')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('name')
          + fieldOverride.byName.withProperty('displayName', 'Name'),
          fieldOverride.byName.new('image')
          + fieldOverride.byName.withProperty('displayName', 'Image'),
          fieldOverride.byName.new('Value')
          + fieldOverride.byName.withProperty('custom.hidden', true),
        ])
        + table.queryOptions.withTargets([
          prometheus.withExpr('sum(container_cpu_user_seconds_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}) by (name,image)') + prometheus.withFormat('table') + prometheus.withInstant(true),
        ]);

      local cpu =
        timeSeriesPanel.new('CPU Usage')
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit('percent')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.standardOptions.withMax(100)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + tooltipSortDesc
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('rate(container_cpu_user_seconds_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m]) * 100', '{{name}}'),
        ]);

      local timeSeriesBase(title, unit) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit(unit)
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + tooltipSortDesc;

      local memory =
        timeSeriesBase('Memory Utilization', 'bytes')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('container_memory_usage_bytes{cluster="$cluster", job=~"$job", image!="", name=~"$container"}', '{{name}}'),
        ]);

      local containerDiskUsage =
        timeSeriesBase('Container Disk Usage', 'bytes')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('container_fs_usage_bytes{cluster="$cluster", job=~"$job", image!="", name=~"$container"}', '{{name}}'),
        ]);

      local DiskIO =
        timeSeriesPanel.new('Disk I/O')
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit('bytes')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(0)
        + timeSeriesPanel.fieldConfig.defaults.custom.withAxisPlacement('left')
        + tooltipSortDesc
        + timeSeriesPanel.standardOptions.withOverrides([
          fieldOverride.byRegexp.new('/io time.*/')
            + fieldOverride.byRegexp.withProperty('unit', 's')
            + fieldOverride.byRegexp.withProperty('custom.axisPlacement', 'right'),
          fieldOverride.byRegexp.new('/read.*|written.*/')
            + fieldOverride.byRegexp.withProperty('custom.axisPlacement', 'left'),
        ])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(rate(container_fs_reads_bytes_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])) by (name)', 'read {{name}}'),
          promTarget('sum(rate(container_fs_writes_bytes_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])) by (name)', 'written {{name}}'),
          promTarget('sum(rate(container_fs_io_time_seconds_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])) by (name)', 'io time {{name}}'),
        ]);

      local bandwidth =
        timeSeriesStacked('Transmit/Receive Bandwidth', 'Bps')
        + timeSeriesPanel.standardOptions.withOverrides(rxTxOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('irate(container_network_transmit_bytes_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', 'Tx_{{name}}'),
          promTarget('irate(container_network_receive_bytes_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', 'Rx_{{name}}'),
        ]);

      local drops =
        timeSeriesStacked('Transmit/Receive Drops', 'pps')
        + timeSeriesPanel.standardOptions.withOverrides(rxTxOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('irate(container_network_transmit_packets_dropped_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', 'Tx_{{name}}'),
          promTarget('irate(container_network_receive_packets_dropped_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', 'Rx_{{name}}'),
        ]);

      local errors =
        timeSeriesStacked('Transmit/Receive Errors', 'pps')
        + timeSeriesPanel.standardOptions.withOverrides(rxTxOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('irate(container_network_transmit_errors_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', 'Tx_{{name}}'),
          promTarget('irate(container_network_receive_errors_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', 'Rx_{{name}}'),
        ]);

      local panels = [
        row.new('Overview') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        containers { gridPos: { x: 0, y: 1, w: 4, h: 5 } },
        imageTable { gridPos: { x: 4, y: 1, w: 20, h: 5 } },
        row.new('CPU Utilization') + { gridPos: { x: 0, y: 6, w: 24, h: 1 } },
        cpu { gridPos: { x: 0, y: 7, w: 24, h: 7 } },
        row.new('Memory Utilization') + { gridPos: { x: 0, y: 14, w: 24, h: 1 } },
        memory { gridPos: { x: 0, y: 15, w: 24, h: 7 } },
        row.new('Disk Utilization') + { gridPos: { x: 0, y: 22, w: 24, h: 1 } },
        containerDiskUsage { gridPos: { x: 0, y: 23, w: 12, h: 7 } },
        DiskIO { gridPos: { x: 12, y: 23, w: 12, h: 7 } },
        row.new('Network Bandwith') + { gridPos: { x: 0, y: 30, w: 24, h: 1 } },
        bandwidth { gridPos: { x: 0, y: 31, w: 24, h: 7 } },
        row.new('Network Drops') + { gridPos: { x: 0, y: 38, w: 24, h: 1 } },
        drops { gridPos: { x: 0, y: 39, w: 24, h: 7 } },
        row.new('Network Errors') + { gridPos: { x: 0, y: 46, w: 24, h: 1 } },
        errors { gridPos: { x: 0, y: 47, w: 24, h: 7 } },
      ];

      dashboard.new('CAdvisor')
      + dashboard.withUid($._config.grafanaDashboards.ids.cAdvisor)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(container_cpu_user_seconds_total{cluster="$cluster"}, job)'),
        $.grafanaTemplates.containerTemplate('label_values(container_cpu_user_seconds_total{cluster="$cluster", job=~"$job"}, name)'),
      ])
      + dashboard.withPanels(panels),
  },
}
