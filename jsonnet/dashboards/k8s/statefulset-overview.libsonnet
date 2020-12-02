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

/* K8s statefulset overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'statefulset-overview':
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
          query='label_values(kube_statefulset_status_replicas, cluster)',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      local colors = [$._config.grafanaDashboards.color.green, $._config.grafanaDashboards.color.orange, $._config.grafanaDashboards.color.red];
      local thresholds = [1, 1];
      local rangeMaps = [
        { from: 0, text: 'OK', to: 0 },
        { from: 1, text: 'Failed', to: 300000 },
      ];

      local statefulSetsTable =
        table.new(
          title='StatefulSets',
          datasource='$datasource',
          sort={ col: 4, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Updated', pattern: 'Value #A', type: 'number' },
            { alias: 'Ready', pattern: 'Value #B', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
            { alias: 'StatefulSet', pattern: 'statefulset', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-namespace=${__cell_1}&var-statefulset=${__cell_2}&%s' % [$._config.grafanaDashboards.ids.statefulSet, $._config.grafanaDashboards.dataLinkCommonArgs] },
            { alias: 'Namespace', pattern: 'namespace', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-namespace=$__cell&var-pod=All&var-view=pod&var-search=&%s' % [$._config.grafanaDashboards.ids.containerDetail, $._config.grafanaDashboards.dataLinkCommonArgs] },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='sum by (statefulset, namespace) (kube_statefulset_status_replicas_updated{cluster=~"$cluster"})'),
            prometheus.target(format='table', instant=true, expr='sum by (statefulset, namespace) (kube_statefulset_status_replicas{cluster=~"$cluster"}) - sum by (statefulset, namespace) (kube_statefulset_status_replicas_ready{cluster=~"$cluster"})'),
          ]
        );

      dashboard.new(
        'StatefulSet',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.statefulSetOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate])
      .addPanels(
        [
          row.new('StatefulSets') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          statefulSetsTable { gridPos: { x: 0, y: 1, w: 24, h: 26 } },
        ]
      ),
  },
}
