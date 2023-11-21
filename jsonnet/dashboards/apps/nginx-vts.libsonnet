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
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local template = grafana.template;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;

{
  grafanaDashboards+:: {
    'nginx-vts':
      local hostTemplate =
        template.new(
          name='host',
          label='Host',
          datasource='$datasource',
          query='label_values(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod"}, host)',
          refresh=$._config.grafanaDashboards.templateRefresh,
          sort=$._config.grafanaDashboards.templateSort,
          includeAll=true,
          multi=true,
        );

      local serverConnections =
        graphPanel.new(
          title='Server Connections',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('sum(nginx_vts_main_connections{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", status=~"active|writing|reading|waiting"}) by (status)', legendFormat='{{status}}'));

      local serverRequests =
        graphPanel.new(
          title='Server Requests',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('sum(irate(nginx_vts_server_requests_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", host=~"^$host$", code!="total"}[5m])) by (code)', legendFormat='{{code}}'));

      local serverBytes =
        graphPanel.new(
          title='Server Bytes',
          datasource='$datasource',
          format='bytes',
          min=0,
        )
        .addTarget(prometheus.target('sum(irate(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", host=~"^$host$"}[5m])) by (direction)', legendFormat='{{direction}}'));

      local templates =
        [
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
          $.grafanaTemplates.jobTemplate('label_values(nginx_vts_server_bytes_total{cluster="$cluster"}, job)'),
          $.grafanaTemplates.namespaceTemplate('label_values(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job"}, namespace)'),
          $.grafanaTemplates.podTemplate('label_values(nginx_vts_server_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace"}, pod)'),
          hostTemplate,
        ];

      local panels = [
        serverConnections { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 0, w: 24, h: 7 } },
        serverRequests { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 7, w: 12, h: 7 } },
        serverBytes { tooltip+: { sort: 2 }, gridPos: { x: 12, y: 7, w: 12, h: 7 } },
      ];

      dashboard.new(
        'Nginx VTS',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.nginxVts,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
