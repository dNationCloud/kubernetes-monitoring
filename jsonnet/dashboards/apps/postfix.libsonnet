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

/* K8s postfix dashboard */
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    postfix:
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
          query='label_values(postfix_size{cluster=~"$cluster"}, job)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          includeAll=true,
          multi=true,
        );

      local queueSize =
        graphPanel.new(
          title='Postfix Queue Size',
          datasource='$datasource',
          stack=true,
        )
        .addTarget(prometheus.target('sum(postfix_size{cluster=~"$cluster", job=~"$job"})', legendFormat='queue size'));

      local templates = [datasourceTemplate, clusterTemplate, jobTemplate];

      local panels = [
        row.new('Queue Size') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        queueSize { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 1, w: 24, h: 7 } },
      ];

      dashboard.new(
        'Postfix',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sApps,
        uid=$._config.dashboardIDs.postfix,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
