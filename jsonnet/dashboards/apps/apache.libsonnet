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

/* K8s apache dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    apache:
      local timeSeriesBase(title) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + timeSeriesPanel.options.tooltip.withMode('multi')
        + timeSeriesPanel.options.tooltip.withSort('desc');

      local timeSeriesStacked(title) =
        timeSeriesBase(title)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false);

      local requests =
        timeSeriesStacked('Apache Requests per second')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(apache__req_per_sec{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('requests'),
        ]);

      local cpuLoad =
        timeSeriesStacked('Apache CPU Load')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(apache__c_p_u_load{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('load'),
        ]);

      local memoryUtilization =
        timeSeriesStacked('Apache Memory Utilization')
        + timeSeriesPanel.standardOptions.withUnit('bytes')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(apache__total_k_bytes_total{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('total'),
        ]);

      local memoryUtilizationPer =
        timeSeriesStacked('Apache Memory Utilization per Sec/Req')
        + timeSeriesPanel.standardOptions.withUnit('bytes')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(apache__bytes_per_sec{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('bytes per sec'),
          prometheus.withExpr('rate(apache__bytes_per_req{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('bytes per req'),
        ]);

      local workers =
        timeSeriesBase('Apache Workers')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(apache__idle_workers{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('idle'),
          prometheus.withExpr('rate(apache__busy_workers{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('busy'),
        ]);

      local panels = [
        row.new('Requests') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        requests { gridPos: { x: 0, y: 1, w: 24, h: 7 } },
        row.new('CPU Load') + { gridPos: { x: 0, y: 8, w: 24, h: 1 } },
        cpuLoad { gridPos: { x: 0, y: 9, w: 24, h: 7 } },
        row.new('Memory Utilization') + { gridPos: { x: 0, y: 16, w: 24, h: 1 } },
        memoryUtilization { gridPos: { x: 0, y: 17, w: 12, h: 7 } },
        memoryUtilizationPer { gridPos: { x: 12, y: 17, w: 12, h: 7 } },
        row.new('Workers') + { gridPos: { x: 0, y: 24, w: 24, h: 1 } },
        workers { gridPos: { x: 0, y: 25, w: 24, h: 7 } },
      ];

      dashboard.new('Apache')
      + dashboard.withUid($._config.grafanaDashboards.ids.apache)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(apache__c_p_u_load{cluster="$cluster"}, job)'),
      ])
      + dashboard.withPanels(panels),
  },
}
