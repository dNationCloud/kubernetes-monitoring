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

/* K8s statefulset detail dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'statefulset-detail.json':
      local datasourceTemplate =
        template.datasource(
          name='datasource',
          label='Datasource',
          query='prometheus',
          current=null,
        );

      local alertmanagerTemplate =
        template.datasource(
          name='alertmanager',
          label='AlertManager',
          query='camptocamp-prometheus-alertmanager-datasource',
          current=null,
          hide='variable',
        );

      local clusterTemplate =
        template.new(
          name='cluster',
          label='Cluster',
          datasource='$datasource',
          query='label_values(kube_statefulset_status_replicas, cluster)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local nodesTable =
        table.new(
          title='Stateful Sets',
          datasource='$datasource',
          sort={ col: 2, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Desired', pattern: 'Value #A', type: 'number', decimals: 0 },
            { alias: 'Current', pattern: 'Value #B', type: 'number', decimals: 0 },
            { alias: 'Ready', pattern: 'Value #C', type: 'number', decimals: 0 },
            { alias: 'Desired/Ready', pattern: 'Value #D', type: 'number', decimals: 0, unit: 'percent', thresholds: [95, 99], colorMode: 'cell', colors: [$._config.dashboardCommon.color.red, $._config.dashboardCommon.color.orange, $._config.dashboardCommon.color.green] },
            { alias: 'Namespace', pattern: 'namespace', type: 'string' },
            { alias: 'Stateful Set', pattern: 'statefulset', link: true, linkTargetBlank: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-namespace=${__cell_1}&var-statefulset=${__cell_2}&var-view=statefulset&%s' % [$._config.dashboardIDs.statefulSet, $._config.dashboardCommon.dataLinkCommonArgs] },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='sum by (statefulset, namespace) (kube_statefulset_status_replicas{cluster=~"$cluster"})'),
            prometheus.target(format='table', instant=true, expr='sum by (statefulset, namespace) (kube_statefulset_status_replicas_current{cluster=~"$cluster", %(stateMetrics)s})' % $._config.dashboardSelectors),
            prometheus.target(format='table', instant=true, expr='sum by (statefulset, namespace) (kube_statefulset_status_replicas_ready{cluster=~"$cluster", %(stateMetrics)s})' % $._config.dashboardSelectors),
            prometheus.target(format='table', instant=true, expr='\n(sum by (statefulset, namespace) (kube_statefulset_status_replicas_current{cluster=~"$cluster", %(stateMetrics)s}) ) / (sum by (statefulset, namespace) (kube_statefulset_status_replicas{cluster=~"$cluster", %(stateMetrics)s}) ) * 100' % $._config.dashboardSelectors),
          ]
        );

      dashboard.new(
        'Stateful Set',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sDetail,
        uid=$._config.dashboardIDs.statefulSetDetail,
      )
      .addTemplates([datasourceTemplate, alertmanagerTemplate, clusterTemplate])
      .addPanels(
        [
          row.new('Stateful Sets') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          nodesTable { gridPos: { x: 0, y: 1, w: 24, h: 26 } },
        ]
      ),
  },
}
