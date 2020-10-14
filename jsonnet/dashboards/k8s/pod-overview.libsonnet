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

/* K8s pod overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local table = grafana.tablePanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    'pod-overview':
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
          query='label_values(kube_pod_info, cluster)',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local colors = [$._config.dashboardCommon.color.green, $._config.dashboardCommon.color.orange, $._config.dashboardCommon.color.red];
      local valueMaps = [
        { text: 'Running', value: 1 },
        { text: 'Succeeded', value: 2 },
        { text: 'Unknown', value: 3 },
        { text: 'Failed', value: 4 },
        { text: 'Pending', value: 5 },
      ];

      local podsTable =
        table.new(
          title='Pods',
          datasource='$datasource',
          sort={ col: 3, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Status', pattern: 'Value', type: 'string', mappingType: 1, valueMaps: valueMaps, thresholds: [3, 3], colorMode: 'cell', colors: colors },
            { alias: 'Namespace', pattern: 'namespace', type: 'string' },
            { alias: 'Pod', pattern: 'pod', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-container=All&var-view=pod&var-namespace=${__cell_1}&var-pod=${__cell_2}&var-search=&%s' % [$._config.dashboardIDs.containerDetail, $._config.dashboardCommon.dataLinkCommonArgs] },
          ]
        )
        .addTarget(
            prometheus.target(format='table', instant=true, expr=|||
                sum by (namespace, pod) (kube_pod_status_phase{cluster=~"$cluster", phase="Running"} * 1) +
                sum by (namespace, pod) (kube_pod_status_phase{cluster=~"$cluster", phase="Succeeded"} * 2) +
                sum by (namespace, pod) (kube_pod_status_phase{cluster=~"$cluster", phase="Unknown"} * 3) +
                sum by (namespace, pod) (kube_pod_status_phase{cluster=~"$cluster", phase="Failed"} * 4) +
                sum by (namespace, pod) (kube_pod_status_phase{cluster=~"$cluster", phase="Pending"} * 5)
            |||)
        );

      dashboard.new(
        'Pod',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sOverview,
        uid=$._config.dashboardIDs.podOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate])
      .addPanels(
        [
          row.new('Pods') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          podsTable { gridPos: { x: 0, y: 1, w: 24, h: 26 } },
        ]
      ),
  },
}
