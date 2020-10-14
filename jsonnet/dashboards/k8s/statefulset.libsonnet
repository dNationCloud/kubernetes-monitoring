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

/* K8s statefulset dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local statPanel = grafana.statPanel;
local graphPanel = grafana.graphPanel;
local template = grafana.template;

{
  grafanaDashboards+:: {
    'statefulset':
      local greenStep = { color: $._config.dashboardCommon.color.green, value: null };
      local redStep = { color: $._config.dashboardCommon.color.red, value: 80 };

      local panel(title, expr, unit='none') =
        statPanel.new(
          title=title,
          datasource='$datasource',
          unit=unit,
        )
        .addThreshold(greenStep)
        .addTarget(prometheus.target(expr));

      local cpuPanel =
        panel(
          title='CPU',
          expr='sum(rate(container_cpu_usage_seconds_total{%(kubelet)s, metrics_path="/metrics/cadvisor", cluster=~"$cluster", namespace=~"$namespace", pod=~"$statefulset.*"}[3m]))' % $._config.dashboardSelectors,
          unit='cores',
        );

      local memoryPanel =
        panel(
          title='Memory',
          expr='sum(container_memory_working_set_bytes{%(kubelet)s, metrics_path="/metrics/cadvisor", cluster=~"$cluster", namespace=~"$namespace", pod=~"$statefulset.*", container!="POD", id!="", container!=""})' % $._config.dashboardSelectors,
          unit='bytes',
        );

      local networkPanel =
        panel(
          title='Network',
          expr='sum(rate(container_network_transmit_bytes_total{%(kubelet)s, metrics_path="/metrics/cadvisor", cluster=~"$cluster", namespace=~"$namespace", pod=~"$statefulset.*"}[3m])) + sum(rate(container_network_receive_bytes_total{cluster=~"$cluster", namespace=~"$namespace", pod=~"$statefulset.*"}[3m]))' % $._config.dashboardSelectors,
          unit='Bps',
        );

      local desiredReplicasPanel =
        panel(
          title='Desired Replicas',
          expr='sum(kube_statefulset_status_replicas{cluster=~"$cluster", namespace=~"$namespace", statefulset=~"$statefulset"})',
        )
        .addThreshold(redStep);

      local currentReplicasPanel =
        panel(
          title='Replicas of current version',
          expr='sum(kube_statefulset_status_replicas_current{cluster=~"$cluster", namespace=~"$namespace", statefulset=~"$statefulset"})',
        )
        .addThreshold(redStep);

      local observedGenerationPanel =
        panel(
          title='Observed Generation',
          expr='sum(kube_statefulset_status_observed_generation{cluster=~"$cluster", namespace=~"$namespace", statefulset=~"$statefulset"})',
        )
        .addThreshold(redStep);

      local metadataGenerationPanel =
        panel(
          title='Metadata Generation',
          expr='sum(kube_statefulset_metadata_generation{statefulset=~"$statefulset", cluster=~"$cluster", namespace=~"$namespace"})',
        )
        .addThreshold(redStep);

      local replicasGraphPanel =
        graphPanel.new(
          title='Replicas',
          datasource='$datasource',
        )
        .addTargets(
          [
            prometheus.target(legendFormat='replicas specified {{statefulset}}', expr='sum(kube_statefulset_replicas{statefulset=~"$statefulset", cluster=~"$cluster", namespace=~"$namespace"}) by (statefulset)'),
            prometheus.target(legendFormat='replicas created {{statefulset}}', expr='sum(kube_statefulset_status_replicas{statefulset=~"$statefulset", cluster=~"$cluster", namespace=~"$namespace"}) by (statefulset)'),
            prometheus.target(legendFormat='ready {{statefulset}}', expr='sum(kube_statefulset_status_replicas_ready{statefulset=~"$statefulset", cluster=~"$cluster", namespace=~"$namespace"}) by (statefulset)'),
            prometheus.target(legendFormat='replicas of current version {{statefulset}}', expr='sum(kube_statefulset_status_replicas_current{statefulset=~"$statefulset", cluster=~"$cluster", namespace=~"$namespace"}) by (statefulset)'),
            prometheus.target(legendFormat='updated {{statefulset}}', expr='sum(kube_statefulset_status_replicas_updated{statefulset=~"$statefulset", cluster=~"$cluster", namespace=~"$namespace"}) by (statefulset)'),
          ]
        );

      local datasourceTemplate =
        template.datasource(
          query='prometheus',
          name='datasource',
          current=null,
          label='Datasource',
        );

      local clusterTemplate =
        template.new(
          name='cluster',
          query='label_values(kube_statefulset_metadata_generation, cluster)',
          label='Cluster',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local namespaceTemplate =
        template.new(
          name='namespace',
          query='label_values(kube_statefulset_metadata_generation{cluster=~"$cluster"}, namespace)',
          label='Namespace',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          multi=true,
          includeAll=true,
        );

      local statefulsetTemplate =
        template.new(
          name='statefulset',
          query='label_values(kube_statefulset_metadata_generation{cluster=~"$cluster", namespace=~"$namespace"}, statefulset)',
          label='StatefulSet',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          multi=true,
          includeAll=true,
        );

      dashboard.new(
        'StatefulSet Detail',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sStateful,
        uid=$._config.dashboardIDs.statefulSet,
      )
      .addTemplates([datasourceTemplate, clusterTemplate, namespaceTemplate, statefulsetTemplate])
      .addPanels(
        [
          cpuPanel { gridPos: { x: 0, y: 0, w: 8, h: 7 } },
          memoryPanel { gridPos: { x: 8, y: 0, w: 8, h: 7 } },
          networkPanel { gridPos: { x: 16, y: 0, w: 8, h: 7 } },
          desiredReplicasPanel { gridPos: { x: 0, y: 7, w: 6, h: 3 } },
          currentReplicasPanel { gridPos: { x: 6, y: 7, w: 6, h: 3 } },
          observedGenerationPanel { gridPos: { x: 12, y: 7, w: 6, h: 3 } },
          metadataGenerationPanel { gridPos: { x: 18, y: 7, w: 6, h: 3 } },
          replicasGraphPanel { gridPos: { x: 0, y: 10, w: 24, h: 7 }, tooltip+: { sort: 2 } },
        ]
      ),
  },
}
