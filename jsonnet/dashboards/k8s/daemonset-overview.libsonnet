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

/* K8s daemonset overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'daemonset-overview':
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
          query='label_values(kube_daemonset_status_desired_number_scheduled, cluster)',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      local namespaceTemplate =
        template.new(
          name='namespace',
          label='Namespace',
          query='label_values(kube_daemonset_status_desired_number_scheduled{cluster=~"$cluster"}, namespace)',
          datasource='$datasource',
          refresh=$._config.grafanaDashboards.templateRefresh,
          sort=$._config.grafanaDashboards.templateSort,
          includeAll=true,
          multi=true,
        );

      local daemonSetTemplate =
        template.new(
          name='daemonset',
          label='DaemonSet',
          query='label_values(kube_daemonset_status_desired_number_scheduled{cluster=~"$cluster", namespace=~"$namespace"}, daemonset)',
          datasource='$datasource',
          refresh=$._config.grafanaDashboards.templateRefresh,
          sort=$._config.grafanaDashboards.templateSort,
          includeAll=true,
          multi=true,
        );

      local colors = [$._config.grafanaDashboards.color.green, $._config.grafanaDashboards.color.orange, $._config.grafanaDashboards.color.red];
      local thresholds = [1, 1];
      local rangeMaps = [
        { from: 0, text: 'OK', to: 0 },
        { from: 1, text: 'Failed', to: $._config.grafanaDashboards.constants.infinity },
      ];

      local daemonSetsTable =
        table.new(
          title='DaemonSets',
          datasource='$datasource',
          sort={ col: 6, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Scheduled', pattern: 'Value #A', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
            { alias: 'Updated', pattern: 'Value #B', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
            { alias: 'Available', pattern: 'Value #C', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
            { alias: 'Ready', pattern: 'Value #D', type: 'string', mappingType: 2, rangeMaps: rangeMaps, thresholds: thresholds, colorMode: 'cell', colors: colors },
            { alias: 'DaemonSet', pattern: 'daemonset', type: 'string' },
            { alias: 'Namespace', pattern: 'namespace', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-namespace=$__cell&var-pod=All&var-view=pod&var-search=&%s' % [$._config.grafanaDashboards.ids.containerDetail, $._config.grafanaDashboards.dataLinkCommonArgs] },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='sum by (daemonset, namespace) (kube_daemonset_status_number_misscheduled{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"})'),
            prometheus.target(format='table', instant=true, expr='sum by (daemonset, namespace) (kube_daemonset_status_desired_number_scheduled{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"}) - sum by (daemonset, namespace) (kube_daemonset_updated_number_scheduled{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"})'),
            prometheus.target(format='table', instant=true, expr='sum by (daemonset, namespace) (kube_daemonset_status_desired_number_scheduled{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"}) - sum by (daemonset, namespace) (kube_daemonset_status_number_available{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"})'),
            prometheus.target(format='table', instant=true, expr='sum by (daemonset, namespace) (kube_daemonset_status_desired_number_scheduled{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"}) - sum by (daemonset, namespace) (kube_daemonset_status_number_ready{cluster=~"$cluster", namespace=~"$namespace", daemonset=~"$daemonset"})'),
          ]
        );

      dashboard.new(
        'DaemonSet',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.daemonSetOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate, namespaceTemplate, daemonSetTemplate])
      .addPanels(
        [
          row.new('DaemonSets') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          daemonSetsTable { gridPos: { x: 0, y: 1, w: 24, h: 26 } },
        ]
      ),
  },
}
