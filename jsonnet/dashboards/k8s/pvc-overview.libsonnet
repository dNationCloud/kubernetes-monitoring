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

/* K8s pvc overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'pvc-overview':
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
          query='label_values(kube_persistentvolumeclaim_info, cluster)',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      local namespaceTemplate =
        template.new(
          name='namespace',
          label='Namespace',
          query='label_values(kube_persistentvolumeclaim_info{cluster=~"$cluster"}, namespace)',
          datasource='$datasource',
          refresh=$._config.grafanaDashboards.templateRefresh,
          sort=$._config.grafanaDashboards.templateSort,
          includeAll=true,
          multi=true,
        );

      local pvcTemplate =
        template.new(
          name='pvc',
          label='PVC',
          query='label_values(kube_persistentvolumeclaim_info{cluster=~"$cluster", namespace=~"$namespace"}, persistentvolumeclaim)',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          multi=true,
          includeAll=true,
        );

      local colors = [$._config.grafanaDashboards.color.green, $._config.grafanaDashboards.color.orange, $._config.grafanaDashboards.color.red];
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
          description='Capacity is available only for remote pvc.',
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Capacity', pattern: 'Value #A', colors: colors, colorMode: 'cell', type: 'number', unit: 'percent', thresholds: [85, 97] },
            { alias: 'Status', pattern: 'Value #B', colors: colors, colorMode: 'cell', type: 'string', thresholds: [2, 2], valueMaps: valueMaps, mappingType: 1 },
            { alias: 'PVC', pattern: 'persistentvolumeclaim', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-namespace=${__cell_1}&var-volume=${__cell_2}&%s' % [$._config.grafanaDashboards.ids.persistentVolumes, $._config.grafanaDashboards.dataLinkCommonArgs] },
            { alias: 'Namespace', pattern: 'namespace', type: 'string' },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='sum by (persistentvolumeclaim, namespace) (((kubelet_volume_stats_capacity_bytes{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"} - kubelet_volume_stats_available_bytes{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"}) / kubelet_volume_stats_capacity_bytes{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc"}) * 100)'),
            prometheus.target(format='table', instant=true, expr=|||
              sum by (persistentvolumeclaim, namespace) (kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc", phase="Bound"} * 1) +
              sum by (persistentvolumeclaim, namespace) (kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc", phase="Lost"} * 2) +
              sum by (persistentvolumeclaim, namespace) (kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", namespace=~"$namespace", persistentvolumeclaim=~"$pvc", phase="Pending"} * 3)
            |||),
          ]
        );

      dashboard.new(
        'PVC',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.pvcOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate, namespaceTemplate, pvcTemplate])
      .addPanels(
        [
          row.new('Persistent Volumes') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          pvcTable { gridPos: { x: 0, y: 1, w: 24, h: 19 } },
        ]
      ),
  },
}
