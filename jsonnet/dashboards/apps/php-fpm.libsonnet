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
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    'php-fpm':
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
          query='label_values(fpm_accepted_conn_total{cluster=~"$cluster"}, job)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          includeAll=true,
          multi=true,
        );

      local acceptedConnections =
        graphPanel.new(
          title='PHP FPM accepted connections',
          datasource='$datasource',
          stack=true,
        )
        .addTarget(prometheus.target('rate(fpm_accepted_conn_total{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='connections'));

      local slowRequests =
        graphPanel.new(
          title='PHP FPM slow requests',
          datasource='$datasource',
          stack=true,
        )
        .addTarget(prometheus.target('rate(fpm_slow_requests_total{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='requests'));

      local processes =
        graphPanel.new(
          title='PHP FPM processes',
          datasource='$datasource',
        )
        .addTargets(
          [
            prometheus.target('rate(fpm_max_active_processes{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='max active processes'),
            prometheus.target('rate(fpm_active_processes{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='active processes'),
            prometheus.target('rate(fpm_total_processes{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='total processes'),
            prometheus.target('rate(fpm_idle_processes{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='idle processes'),
          ],
        );

      local childrenProcesses =
        graphPanel.new(
          title='PHP FPM max children processes reached',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('rate(fpm_max_children_reached{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='children processes'));

      local listenQueue =
        graphPanel.new(
          title='PHP FPM listen queue',
          datasource='$datasource',
        )
        .addTargets(
          [
            prometheus.target('rate(fpm_max_listen_queue{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='max listen queue'),
            prometheus.target('rate(fpm_listen_queue{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='listen queue'),
            prometheus.target('rate(fpm_listen_queue_len{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='listen queue len'),
          ],
        );

      local templates = [datasourceTemplate, clusterTemplate, jobTemplate];

      local panels = [
        row.new('Connections') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        acceptedConnections { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 1, w: 24, h: 7 } },
        row.new('Requests', collapse=true) { gridPos: { x: 0, y: 8, w: 24, h: 1 } }
        .addPanel(slowRequests { tooltip+: { sort: 2 } }, { x: 0, y: 9, w: 24, h: 7 }),
        row.new('Processes') { gridPos: { x: 0, y: 9, w: 24, h: 1 } },
        processes { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 10, w: 12, h: 7 } },
        childrenProcesses { tooltip+: { sort: 2 }, gridPos: { x: 12, y: 10, w: 12, h: 7 } },
        row.new('Queue') { gridPos: { x: 0, y: 17, w: 24, h: 1 } },
        listenQueue { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 18, w: 24, h: 7 } },
      ];

      dashboard.new(
        'PHP FPM',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sApp,
        uid=$._config.dashboardIDs.phpFpm,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
