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

/* K8s persistent volumes dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local gaugePanel = grafana.panel.gauge;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    pvc:
      local sel = $._config.grafanaDashboards.selectors;

      local timeSeriesStacked(title, unit) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit(unit)
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + timeSeriesPanel.options.legend.withDisplayMode('table')
        + timeSeriesPanel.options.legend.withCalcs(['mean', 'lastNotNull', 'max', 'min'])
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc');

      local gaugeBase(title, expr) =
        gaugePanel.new(title)
        + gaugePanel.queryOptions.withDatasource('prometheus', '$datasource')
        + gaugePanel.standardOptions.withUnit('percent')
        + gaugePanel.standardOptions.withMin(0)
        + gaugePanel.standardOptions.withMax(100)
        + gaugePanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + gaugePanel.standardOptions.thresholds.withMode('absolute')
        + gaugePanel.standardOptions.thresholds.withSteps([{ color: $._config.grafanaDashboards.color.blue, value: null }])
        + gaugePanel.queryOptions.withTargets([prometheus.withExpr(expr)]);

      local volSpaceUsageGraphPanel =
        timeSeriesStacked('Volume Space Usage', 'bytes')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('(\n  sum by (persistentvolumeclaim) (kubelet_volume_stats_capacity_bytes{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"})\n  -\n  sum by (persistentvolumeclaim) (kubelet_volume_stats_available_bytes{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"})\n)' % sel) + prometheus.withLegendFormat('Used Space {{persistentvolumeclaim}}'),
          prometheus.withExpr('sum by (persistentvolumeclaim) (kubelet_volume_stats_available_bytes{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"})' % sel) + prometheus.withLegendFormat('Free Space {{persistentvolumeclaim}}'),
        ]);

      local volSpaceUsageGaugePanel =
        gaugeBase('Volume Space Usage', '(\n  sum(kubelet_volume_stats_capacity_bytes{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"})\n  -\n  sum(kubelet_volume_stats_available_bytes{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"})\n)\n/\nsum(kubelet_volume_stats_capacity_bytes{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"})\n* 100' % sel);

      local volInodesUsageGraphPanel =
        timeSeriesStacked('Volume inodes Usage', 'none')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum by (persistentvolumeclaim) (kubelet_volume_stats_inodes_used{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"})' % sel) + prometheus.withLegendFormat('Used inodes {{persistentvolumeclaim}}'),
          prometheus.withExpr('(\n  sum by (persistentvolumeclaim) (kubelet_volume_stats_inodes{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace="$namespace", persistentvolumeclaim=~"$pvc"})\n  -\n  sum by (persistentvolumeclaim) (kubelet_volume_stats_inodes_used{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"})\n)' % sel) + prometheus.withLegendFormat('Free inodes {{persistentvolumeclaim}}'),
        ]);

      local volInodesUsageGaugePanel =
        gaugeBase('Volume inodes Usage', 'sum(kubelet_volume_stats_inodes_used{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"})\n/\nsum(kubelet_volume_stats_inodes{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"})\n* 100' % sel);

      dashboard.new('Persistent Volumes')
      + dashboard.withUid($._config.grafanaDashboards.ids.persistentVolumes)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sPVC)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(kubelet_volume_stats_capacity_bytes, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kubelet_volume_stats_capacity_bytes{cluster="$cluster", %(kubelet)s, metrics_path="/metrics"}, namespace)' % sel),
        $.grafanaTemplates.pvcTemplate('label_values(kubelet_volume_stats_capacity_bytes{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace"}, persistentvolumeclaim)' % sel),
      ])
      + dashboard.withPanels([
        volSpaceUsageGraphPanel { gridPos: { x: 0, y: 0, w: 18, h: 7 } },
        volSpaceUsageGaugePanel { gridPos: { x: 18, y: 0, w: 6, h: 7 } },
        volInodesUsageGraphPanel { gridPos: { x: 0, y: 7, w: 18, h: 7 } },
        volInodesUsageGaugePanel { gridPos: { x: 18, y: 7, w: 6, h: 7 } },
      ]),
  },
}
