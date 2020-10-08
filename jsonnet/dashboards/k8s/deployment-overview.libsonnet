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

/* K8s deployment overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'deployment-overview.json':
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
          query='label_values(kube_deployment_status_replicas, cluster)',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local colors = [$._config.dashboardCommon.color.red, $._config.dashboardCommon.color.orange, $._config.dashboardCommon.color.green];
      local thresholds = [1, 1];
      local rangeMaps = [
        { from: '1', text: 'OK', to: '1' },
        { from: '0', text: 'Failed', to: '1' },
      ];

      local deploymentsTable =
        table.new(
          title='Deployments',
          datasource='$datasource',
          sort={ col: 3 },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Available', pattern: 'Value #A', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
            { alias: 'Updated', pattern: 'Value #B', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
            { alias: 'Deployment', pattern: 'deployment', type: 'string' },
            { alias: 'Namespace', pattern: 'namespace', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-namespace=$__cell&var-pod=All&var-view=pod&var-search=&%s' % [$._config.dashboardIDs.containerDetail, $._config.dashboardCommon.dataLinkCommonArgs] },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='sum by (deployment, namespace) (kube_deployment_status_replicas_available{cluster=~"$cluster"}) / sum by (deployment, namespace) (kube_deployment_status_replicas{cluster=~"$cluster"})'),
            prometheus.target(format='table', instant=true, expr='sum by (deployment, namespace) (kube_deployment_status_replicas_updated{cluster=~"$cluster"}) / sum by (deployment, namespace) (kube_deployment_status_replicas{cluster=~"$cluster"})'),
          ]
        );

      dashboard.new(
        'Deployment',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sOverview,
        uid=$._config.dashboardIDs.deploymentOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate])
      .addPanels(
        [
          row.new('Deployments') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          deploymentsTable { gridPos: { x: 0, y: 1, w: 24, h: 26 } },
        ]
      ),
  },
}
