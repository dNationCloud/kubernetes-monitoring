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
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    'nginx-nrpe':
      local datasourceTemplate =
        template.datasource(
          name='datasource',
          label='Datasource',
          query='prometheus',
          current=null,
        );

      local clusterTemplate =
        template.new(
          name='cluster',
          label='Cluster',
          datasource='$datasource',
          query='label_values(node_uname_info, cluster)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local jobTemplate =
        template.new(
          name='job',
          label='Job',
          datasource='$datasource',
          query='label_values(nginx_accepts_total{cluster=~"$cluster"}, job)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          includeAll=true,
          multi=true,
        );

      local connections1 =
        graphPanel.new(
          title='Nginx connections',
          datasource='$datasource',
          stack=true,
        )
        .addTargets(
          [
            prometheus.target('rate(nginx_accepts_total{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='accepts'),
            prometheus.target('rate(nginx_handled_total{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='handled'),
            prometheus.target('rate(nginx_active{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='active'),
          ],
        );

      local connections2 =
        graphPanel.new(
          title='Nginx connections',
          datasource='$datasource',
          stack=true,
        )
        .addTargets(
          [
            prometheus.target('rate(nginx_reading{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='reading'),
            prometheus.target('rate(nginx_writing{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='writing'),
            prometheus.target('rate(nginx_waiting{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='waiting'),
          ],
        );

      local requests =
        graphPanel.new(
          title='Nginx requests',
          datasource='$datasource',
          stack=true,
        )
        .addTarget(prometheus.target('rate(nginx_requests_total{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='requests'));

      local templates = [datasourceTemplate, clusterTemplate, jobTemplate];

      local panels = [
        row.new('Connections') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        connections1 { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 1, w: 24, h: 7 } },
        connections2 { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 8, w: 24, h: 7 } },
        row.new('Requests') { gridPos: { x: 0, y: 15, w: 24, h: 1 } },
        requests { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 16, w: 24, h: 7 } },
      ];

      dashboard.new(
        'Nginx Nrpe',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sApp,
        uid=$._config.dashboardIDs.nginxNrpe,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
