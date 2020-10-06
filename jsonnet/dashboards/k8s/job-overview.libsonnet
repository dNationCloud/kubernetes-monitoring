/*
  Copyright 2020 The K8s-m8g Authors. All Rights Reserved.
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

/* K8s job overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'job-overview.json':
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
          query='label_values(kube_job_info, cluster)',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local colors = [$._config.dashboardCommon.color.green, $._config.dashboardCommon.color.orange, $._config.dashboardCommon.color.red];
      local valueMaps = [
        { text: 'Succeeded', value: 1 },
        { text: 'Active', value: 2 },
        { text: 'Failed', value: 3 },
      ];

      local jobsTable =
        table.new(
          title='Jobs',
          datasource='$datasource',
          sort={ col: 3, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Status', pattern: 'Value', colors: colors, colorMode: 'cell', type: 'string', thresholds: [3, 3], valueMaps: valueMaps, mappingType: 1 },
            { alias: 'Job name', pattern: 'job_name', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-container=${__cell_1}&var-namespace=${__cell_2}&var-view=container&var-search=&%s' % [$._config.dashboardIDs.logs, $._config.dashboardCommon.dataLinkCommonArgs] },
            { alias: 'Namespace', pattern: 'namespace', type: 'string' },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr=|||
              sum by (job_name, namespace) (kube_job_status_succeeded{cluster=~"$cluster"} * 1) +
              sum by (job_name, namespace) (kube_job_status_active{cluster=~"$cluster"} * 2) +
              sum by (job_name, namespace) (kube_job_status_failed{cluster=~"$cluster"} * 3)
            |||),
          ]
        );

      dashboard.new(
        'Job',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sOverview,
        uid=$._config.dashboardIDs.jobOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate])
      .addPanels(
        [
          row.new('Jobs') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          jobsTable { gridPos: { x: 0, y: 1, w: 24, h: 23 } },
        ]
      ),
  },
}
