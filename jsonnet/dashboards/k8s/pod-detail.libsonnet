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

/* K8s pod detail dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local table = grafana.tablePanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    'pod-detail.json':
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

      local colors = [$._config.dashboardCommon.color.red, $._config.dashboardCommon.color.orange, $._config.dashboardCommon.color.green];
      local colorsInverse = [colors[2], colors[1], colors[0]];
      local thresholds = [1, 1];

      local podsTable =
        table.new(
          title='Pods',
          datasource='$datasource',
          sort={ col: 3, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Namespace', pattern: 'namespace', type: 'string' },
            { alias: 'Pod', pattern: 'pod', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-container=${__cell_1}&var-namespace=${__cell_2}&var-pod=${__cell_3}&var-view=container&var-search=&%s' % [$._config.dashboardIDs.logs, $._config.dashboardCommon.dataLinkCommonArgs] },
            { alias: 'Running', pattern: 'Value #A', type: 'string', colors: colors, colorMode: 'cell', thresholds: thresholds, valueMaps: [{ text: 'OK', value: 1 }], mappingType: 1 },
            { alias: 'Succeeded', pattern: 'Value #B', type: 'string', colors: colors, colorMode: 'cell', thresholds: thresholds, valueMaps: [{ text: 'OK', value: 1 }], mappingType: 1 },
            { alias: 'Failed', pattern: 'Value #C', type: 'string', colors: colorsInverse, colorMode: 'cell', thresholds: thresholds, valueMaps: [{ text: 'Unknown', value: 1 }], mappingType: 1 },
            { alias: 'Failed', pattern: 'Value #D', type: 'string', colors: colorsInverse, colorMode: 'cell', thresholds: thresholds, valueMaps: [{ text: 'Failed', value: 1 }], mappingType: 1 },
            { alias: 'Failed', pattern: 'Value #E', type: 'string', colors: colorsInverse, colorMode: 'cell', thresholds: thresholds, valueMaps: [{ text: 'Pending', value: 1 }], mappingType: 1 },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='sum by (pod, namespace) (kube_pod_status_phase{cluster=~"$cluster", phase="Running"}) > 0'),
            prometheus.target(format='table', instant=true, expr='sum by (pod, namespace) (kube_pod_status_phase{cluster=~"$cluster", phase="Succeeded"}) > 0'),
            prometheus.target(format='table', instant=true, expr='sum by (pod, namespace) (kube_pod_status_phase{cluster=~"$cluster", phase="Unknown"}) > 0'),
            prometheus.target(format='table', instant=true, expr='sum by (pod, namespace) (kube_pod_status_phase{cluster=~"$cluster", phase="Failed"}) > 0'),
            prometheus.target(format='table', instant=true, expr='sum by (pod, namespace) (kube_pod_status_phase{cluster=~"$cluster", phase="Pending"}) > 0'),
          ]
        );

      dashboard.new(
        title='Pod',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sDetail,
        uid=$._config.dashboardIDs.podDetail,
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
