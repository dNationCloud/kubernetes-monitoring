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

/* K8s php fpm dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    'php-fpm':
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

      local acceptedConnections =
        timeSeriesStacked('PHP FPM accepted connections')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(fpm_accepted_conn_total{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('connections'),
        ]);

      local slowRequests =
        timeSeriesStacked('PHP FPM slow requests')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(fpm_slow_requests_total{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('requests'),
        ]);

      local processes =
        timeSeriesBase('PHP FPM processes')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(fpm_max_active_processes{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('max active processes'),
          prometheus.withExpr('rate(fpm_active_processes{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('active processes'),
          prometheus.withExpr('rate(fpm_total_processes{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('total processes'),
          prometheus.withExpr('rate(fpm_idle_processes{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('idle processes'),
        ]);

      local childrenProcesses =
        timeSeriesBase('PHP FPM max children processes reached')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(fpm_max_children_reached{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('children processes'),
        ]);

      local listenQueue =
        timeSeriesBase('PHP FPM listen queue')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('rate(fpm_max_listen_queue{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('max listen queue'),
          prometheus.withExpr('rate(fpm_listen_queue{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('listen queue'),
          prometheus.withExpr('rate(fpm_listen_queue_len{cluster="$cluster", job=~"$job"}[5m])') + prometheus.withLegendFormat('listen queue len'),
        ]);

      local panels = [
        row.new('Connections') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        acceptedConnections { gridPos: { x: 0, y: 1, w: 24, h: 7 } },
        row.new('Requests') + { gridPos: { x: 0, y: 8, w: 24, h: 1 } },
        slowRequests { gridPos: { x: 0, y: 9, w: 24, h: 7 } },
        row.new('Processes') + { gridPos: { x: 0, y: 16, w: 24, h: 1 } },
        processes { gridPos: { x: 0, y: 17, w: 12, h: 7 } },
        childrenProcesses { gridPos: { x: 12, y: 17, w: 12, h: 7 } },
        row.new('Queue') + { gridPos: { x: 0, y: 24, w: 24, h: 1 } },
        listenQueue { gridPos: { x: 0, y: 25, w: 24, h: 7 } },
      ];

      dashboard.new('PHP FPM')
      + dashboard.withUid($._config.grafanaDashboards.ids.phpFpm)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(fpm_accepted_conn_total{cluster="$cluster"}, job)'),
      ])
      + dashboard.withPanels(panels),
  },
}
