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

/* K8s persistent volumes dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local gaugePanel = grafana.gaugePanel;
local graphPanel = grafana.graphPanel;

{
  grafanaDashboards+:: {
    'pvc':
      local usageGraphPanel(title, format) =
        graphPanel.new(
          title=title,
          datasource='$datasource',
          format=format,
          min=0,
          stack=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_current=true,
          legend_max=true,
          legend_min=true,
          legend_values=true,
        );

      local usageGaugePanel(title, expr) =
        gaugePanel.new(
          title=title,
          datasource='$datasource',
          min=0,
          max=100,
        )
        .addThresholds(
          [
            { color: $._config.dashboardCommon.color.green, value: null },
            { color: $._config.dashboardCommon.color.orange, value: 85 },
            { color: $._config.dashboardCommon.color.red, value: 97 },
          ]
        )
        .addTarget(prometheus.target(expr=expr % $._config.dashboardSelectors));

      local volSpaceUsageGraphPanel =
        usageGraphPanel(title='Volume Space Usage', format='bytes')
        .addTargets(
          [
            prometheus.target(legendFormat='Used Space {{persistentvolumeclaim}}', expr='(\n  sum by (persistentvolumeclaim) (kubelet_volume_stats_capacity_bytes{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$volume"})\n  -\n  sum by (persistentvolumeclaim) (kubelet_volume_stats_available_bytes{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$volume"})\n)' % $._config.dashboardSelectors),
            prometheus.target(legendFormat='Free Space {{persistentvolumeclaim}}', expr='sum by (persistentvolumeclaim) (kubelet_volume_stats_available_bytes{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$volume"})' % $._config.dashboardSelectors),
          ]
        );

      local volSpaceUsageGaugePanel =
        usageGaugePanel(title='Volume Space Usage', expr='(\n  sum(kubelet_volume_stats_capacity_bytes{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$volume"})\n  -\n  sum(kubelet_volume_stats_available_bytes{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$volume"})\n)\n/\nsum(kubelet_volume_stats_capacity_bytes{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$volume"})\n* 100');

      local volInodesUsageGraphPanel =
        usageGraphPanel(title='Volume inodes Usage', format='none')
        .addTargets(
          [
            prometheus.target(legendFormat='Used inodes {{persistentvolumeclaim}}', expr='sum by (persistentvolumeclaim) (kubelet_volume_stats_inodes_used{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$volume"})' % $._config.dashboardSelectors),
            prometheus.target(legendFormat='Free inodes {{persistentvolumeclaim}}', expr='(\n  sum by (persistentvolumeclaim) (kubelet_volume_stats_inodes{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace="$namespace", persistentvolumeclaim=~"$volume"})\n  -\n  sum by (persistentvolumeclaim) (kubelet_volume_stats_inodes_used{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$volume"})\n)' % $._config.dashboardSelectors),
          ]
        );

      local volInodesUsageGaugePanel =
        usageGaugePanel(title='Volume inodes Usage', expr='sum(kubelet_volume_stats_inodes_used{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$volume"})\n/\nsum(kubelet_volume_stats_inodes{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace", persistentvolumeclaim=~"$volume"})\n* 100');

      local datasourceTemplate =
        template.datasource(
          query='prometheus',
          name='datasource',
          current=null,
          label='Datasource',
        );

      local clusterTemplate =
        template.new(
          datasource='$datasource',
          query='label_values(kubelet_volume_stats_capacity_bytes, cluster)',
          name='cluster',
          label='Cluster',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local namespaceTemplate =
        template.new(
          datasource='$datasource',
          query='label_values(kubelet_volume_stats_capacity_bytes{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics"}, namespace)' % $._config.dashboardSelectors,
          name='namespace',
          label='Namespace',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          multi=true,
          includeAll=true,
        );

      local pvcTemplate =
        template.new(
          datasource='$datasource',
          query='label_values(kubelet_volume_stats_capacity_bytes{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", namespace=~"$namespace"}, persistentvolumeclaim)' % $._config.dashboardSelectors,
          name='volume',
          label='PVC',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          multi=true,
          includeAll=true,
        );

      dashboard.new(
        'Persistent Volumes',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sPVC,
        uid=$._config.dashboardIDs.persistentVolumes,
      )
      .addTemplates([datasourceTemplate, clusterTemplate, namespaceTemplate, pvcTemplate])
      .addPanels(
        [
          volSpaceUsageGraphPanel { gridPos: { x: 0, y: 0, w: 18, h: 7 }, tooltip+: { sort: 2 } },
          volSpaceUsageGaugePanel { gridPos: { x: 18, y: 0, w: 6, h: 7 } },
          volInodesUsageGraphPanel { gridPos: { x: 0, y: 7, w: 18, h: 7 }, tooltip+: { sort: 2 } },
          volInodesUsageGaugePanel { gridPos: { x: 18, y: 7, w: 6, h: 7 } },
        ]
      ),
  },
}
