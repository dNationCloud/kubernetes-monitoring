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

/* K8s pvc detail dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'pvc-detail.json':
      local datasourceTemplate =
        template.datasource(
          name='datasource',
          label='Datasource',
          query='prometheus',
          current=null,
        );

      local alertManagerTemplate =
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
          query='label_values(kube_persistentvolumeclaim_info, cluster)',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local colors = [$._config.dashboardCommon.color.green, $._config.dashboardCommon.color.orange, $._config.dashboardCommon.color.red];
      local valueMaps = [
        { text: 'Bound', value: 1 },
        { text: 'Lost', value: 2 },
        { text: 'Pending', value: 3 },
      ];

      local pvcTable =
        table.new(
          title='Persistent Volumes',
          datasource='$datasource',
          sort={ col: 3, desc: true },
          styles=[
            { alias: 'Time', pattern: 'Time', type: 'hidden' },
            { alias: 'Capacity', pattern: 'Value #A', colors: colors, colorMode: 'cell', type: 'number', unit: 'percent', thresholds: [85, 97] },
            { alias: 'Status', pattern: 'Value #B', colors: colors, colorMode: 'cell', type: 'string', thresholds: [2, 2], valueMaps: valueMaps, mappingType: 1 },
            { alias: 'PVC', pattern: 'persistentvolumeclaim', type: 'string', link: true, linkTargetBlank: true, linkTooltip: 'Detail', linkUrl: '/d/%s/kubernetes-persistent-volumes?var-namespace=${__cell_1}&var-volume=${__cell_2}&%s' % [$._config.dashboardIDs.persistentVolumes, $._config.dashboardCommon.dataLinkCommonArgs] },
            { alias: 'Namespace', pattern: 'namespace' },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='sum by (persistentvolumeclaim, namespace) (((kubelet_volume_stats_capacity_bytes{cluster=~"$cluster"} - kubelet_volume_stats_available_bytes{cluster=~"$cluster"}) / kubelet_volume_stats_capacity_bytes{cluster=~"$cluster"}) * 100)'),
            prometheus.target(format='table', instant=true, expr=|||
              sum by (persistentvolumeclaim, namespace) (kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", phase="Bound"} * 1) +
              sum by (persistentvolumeclaim, namespace) (kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", phase="Lost"} * 2) +
              sum by (persistentvolumeclaim, namespace) (kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", phase="Pending"} * 3)
            |||),
          ]
        );

      dashboard.new(
        'PVC',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sDetail,
        uid=$._config.dashboardIDs.pvcDetail,
      )
      .addTemplates([datasourceTemplate, alertManagerTemplate, clusterTemplate])
      .addPanels(
        [
          row.new('Persistent Volumes') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          pvcTable { gridPos: { x: 0, y: 1, w: 24, h: 19 } },
        ]
      ),
  },
}
