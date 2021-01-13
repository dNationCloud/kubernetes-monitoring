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

/* K8s node overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'node-overview':
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
          query='label_values(kube_node_status_condition, cluster)',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      local colors = [$._config.grafanaDashboards.color.green, $._config.grafanaDashboards.color.orange, $._config.grafanaDashboards.color.red];
      local valueMaps =
        [
          { text: 'Failed', value: 1 },
          { text: 'OK', value: 0 },
        ];
      local thresholds = [1, 1];

      local nodesTable =
        table.new(
          title='Nodes',
          datasource='$datasource',
          sort={ col: 6, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Schedulable', pattern: 'Value #A', colors: colors, colorMode: 'cell', type: 'string', thresholds: thresholds, valueMaps: valueMaps, mappingType: 1 },
            { alias: 'Disk Pressure', pattern: 'Value #B', colors: colors, colorMode: 'cell', type: 'string', thresholds: thresholds, valueMaps: valueMaps, mappingType: 1 },
            { alias: 'Memory Pressure', pattern: 'Value #C', colors: colors, colorMode: 'cell', type: 'string', thresholds: thresholds, valueMaps: valueMaps, mappingType: 1 },
            { alias: 'PID Pressure', pattern: 'Value #D', colors: colors, colorMode: 'cell', type: 'string', thresholds: thresholds, valueMaps: valueMaps, mappingType: 1 },
            { alias: 'Ready', pattern: 'Value #E', colors: colors, colorMode: 'cell', type: 'string', thresholds: thresholds, valueMaps: valueMaps, mappingType: 1 },
            { alias: 'Node', pattern: 'node', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-view=pod&var-instance=$__cell&%s' % [$._config.grafanaDashboards.ids.containerDetail, $._config.grafanaDashboards.dataLinkCommonArgs] },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='sum by (node) (kube_node_spec_unschedulable{cluster=~"$cluster"})'),
            prometheus.target(format='table', instant=true, expr='sum by (node) (kube_node_status_condition{cluster=~"$cluster", condition="DiskPressure", status=~"true|unknown"})'),
            prometheus.target(format='table', instant=true, expr='sum by (node) (kube_node_status_condition{cluster=~"$cluster", condition="MemoryPressure", status=~"true|unknown"})'),
            prometheus.target(format='table', instant=true, expr='sum by (node) (kube_node_status_condition{cluster=~"$cluster", condition="PIDPressure", status=~"true|unknown"})'),
            prometheus.target(format='table', instant=true, expr='sum by (node) (kube_node_status_condition{cluster=~"$cluster", condition="Ready", status=~"false|unknown"})'),
          ]
        );

      dashboard.new(
        'Node',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.nodeOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate])
      .addPanels(
        [
          row.new('Nodes') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          nodesTable { gridPos: { x: 0, y: 1, w: 24, h: 9 } },
        ]
      ),
  },
}
