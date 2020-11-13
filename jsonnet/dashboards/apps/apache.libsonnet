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
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    apache:
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
          query='label_values(apache__c_p_u_load{cluster=~"$cluster"}, job)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          includeAll=true,
          multi=true,
        );

      local requests =
        graphPanel.new(
          title='Apache Requests per second',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('rate(apache__req_per_sec{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='requests'));

      local cpuLoad =
        graphPanel.new(
          title='Apache CPU Load',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('rate(apache__c_p_u_load{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='load'));

      local memoryUtilization =
        graphPanel.new(
          title='Apache Memory Utilization',
          datasource='$datasource',
          format='bytes',
        )
        .addTarget(prometheus.target('rate(apache__total_k_bytes_total{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='total'));

      local memoryUtilizationPer =
        graphPanel.new(
          title='Apache Memory Utilization per Sec/Req',
          datasource='$datasource',
          format='bytes',
        )
        .addTargets(
          [
            prometheus.target('rate(apache__bytes_per_sec{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='bytes per sec'),
            prometheus.target('rate(apache__bytes_per_req{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='bytes per req'),
          ],
        );

      local workers =
        graphPanel.new(
          title='Apache Workers',
          datasource='$datasource',
        )
        .addTargets(
          [
            prometheus.target('rate(apache__idle_workers{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='idle'),
            prometheus.target('rate(apache__busy_workers{cluster=~"$cluster", job=~"$job"}[5m])', legendFormat='busy'),
          ],
        );

      local templates = [datasourceTemplate, clusterTemplate, jobTemplate];

      local panels = [
        row.new('Requests') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        requests { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 1, w: 24, h: 7 } },
        row.new('CPU Load', collapse=true) { gridPos: { x: 0, y: 8, w: 24, h: 1 } }
        .addPanel(cpuLoad { tooltip+: { sort: 2 } }, { x: 0, y: 9, w: 24, h: 7 }),
        row.new('Memory Utilization', collapse=true) { gridPos: { x: 0, y: 9, w: 24, h: 1 } }
        .addPanel(memoryUtilization { tooltip+: { sort: 2 } }, { x: 0, y: 10, w: 12, h: 7 })
        .addPanel(memoryUtilizationPer { tooltip+: { sort: 2 } }, { x: 12, y: 10, w: 12, h: 7 }),
        row.new('Workers') { gridPos: { x: 0, y: 10, w: 24, h: 1 } },
        workers { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 11, w: 24, h: 7 } },
      ];

      dashboard.new(
        'Apache',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sApps,
        uid=$._config.dashboardIDs.apache,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
