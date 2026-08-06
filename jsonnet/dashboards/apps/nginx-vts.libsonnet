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

/* K8s nginx vts dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    'nginx-vts':
      local timeSeriesBase(title) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + timeSeriesPanel.options.tooltip.withMode('multi')
        + timeSeriesPanel.options.tooltip.withSort('desc');

      local serverConnections =
        timeSeriesBase('Server Connections')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(nginx_vts_main_connections{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", status=~"active|writing|reading|waiting"}) by (status)') + prometheus.withLegendFormat('{{status}}'),
        ]);

      local serverRequests =
        timeSeriesBase('Server Requests')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(irate(nginx_vts_server_requests_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", host=~"^$host$", code!="total"}[5m])) by (code)') + prometheus.withLegendFormat('{{code}}'),
        ]);

      local serverBytes =
        timeSeriesBase('Server Bytes')
        + timeSeriesPanel.standardOptions.withUnit('bytes')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(irate(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", host=~"^$host$"}[5m])) by (direction)') + prometheus.withLegendFormat('{{direction}}'),
        ]);

      local panels = [
        serverConnections { gridPos: { x: 0, y: 0, w: 24, h: 7 } },
        serverRequests { gridPos: { x: 0, y: 7, w: 12, h: 7 } },
        serverBytes { gridPos: { x: 12, y: 7, w: 12, h: 7 } },
      ];

      dashboard.new('Nginx VTS')
      + dashboard.withUid($._config.grafanaDashboards.ids.nginxVts)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(nginx_vts_server_bytes_total{cluster="$cluster"}, job)'),
        $.grafanaTemplates.namespaceTemplate('label_values(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job"}, namespace)'),
        $.grafanaTemplates.podTemplate('label_values(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace"}, pod)'),
        $.grafanaTemplates.baseTemplate('host', 'Host', 'label_values(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod"}, host)'),
      ])
      + dashboard.withPanels(panels),
  },
}
