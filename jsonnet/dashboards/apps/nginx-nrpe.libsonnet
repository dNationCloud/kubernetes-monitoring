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

/* K8s nginx nrpe dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    'nginx-nrpe':
      local timeSeriesStacked(title) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + timeSeriesPanel.options.tooltip.withMode('multi')
        + timeSeriesPanel.options.tooltip.withSort('desc');

      local connections1 =
        timeSeriesStacked('Nginx connections')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(nginx_accepts_total{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('accepts'),
          prometheus.withExpr('rate(nginx_handled_total{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('handled'),
          prometheus.withExpr('rate(nginx_active{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('active'),
        ]);

      local connections2 =
        timeSeriesStacked('Nginx connections')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(nginx_reading{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('reading'),
          prometheus.withExpr('rate(nginx_writing{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('writing'),
          prometheus.withExpr('rate(nginx_waiting{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('waiting'),
        ]);

      local requests =
        timeSeriesStacked('Nginx requests')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(nginx_requests_total{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('requests'),
        ]);

      local panels = [
        row.new('Connections') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        connections1 { gridPos: { x: 0, y: 1, w: 24, h: 7 } },
        connections2 { gridPos: { x: 0, y: 8, w: 24, h: 7 } },
        row.new('Requests') + { gridPos: { x: 0, y: 15, w: 24, h: 1 } },
        requests { gridPos: { x: 0, y: 16, w: 24, h: 7 } },
      ];

      dashboard.new('Nginx Nrpe')
      + dashboard.withUid($._config.grafanaDashboards.ids.nginxNrpe)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(nginx_accepts_total{cluster="$cluster"}, job)'),
      ])
      + dashboard.withPanels(panels),
  },
}
