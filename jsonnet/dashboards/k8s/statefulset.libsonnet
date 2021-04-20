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

/* K8s statefulset dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local statPanel = grafana.statPanel;
local graphPanel = grafana.graphPanel;

{
  grafanaDashboards+:: {
    statefulset:

      local panel(title, expr, unit='none') =
        statPanel.new(
          title=title,
          datasource='$datasource',
          unit=unit,
        )
        .addTarget(prometheus.target(expr));

      local cpuPanel =
        panel(
          title='CPU',
          expr='sum(rate(container_cpu_usage_seconds_total{%(kubelet)s, metrics_path="/metrics/cadvisor", cluster=~"$cluster", namespace=~"$namespace", pod=~"$statefulset.*"}[5m]))' % $._config.grafanaDashboards.selectors,
          unit='cores',
        );

      local memoryPanel =
        panel(
          title='Memory',
          expr='sum(container_memory_working_set_bytes{%(kubelet)s, metrics_path="/metrics/cadvisor", cluster=~"$cluster", namespace=~"$namespace", pod=~"$statefulset.*", container!~"POD|", id!=""})' % $._config.grafanaDashboards.selectors,
          unit='bytes',
        );

      local networkPanel =
        panel(
          title='Network',
          expr='sum(rate(container_network_transmit_bytes_total{%(kubelet)s, metrics_path="/metrics/cadvisor", cluster=~"$cluster", namespace=~"$namespace", pod=~"$statefulset.*"}[5m])) + sum(rate(container_network_receive_bytes_total{cluster=~"$cluster", namespace=~"$namespace", pod=~"$statefulset.*"}[5m]))' % $._config.grafanaDashboards.selectors,
          unit='Bps',
        );

      local desiredReplicasPanel =
        panel(
          title='Desired Replicas',
          expr='sum(kube_statefulset_status_replicas{cluster=~"$cluster", namespace=~"$namespace", statefulset=~"$statefulset"})',
        );

      local currentReplicasPanel =
        panel(
          title='Replicas of current version',
          expr='sum(kube_statefulset_status_replicas_current{cluster=~"$cluster", namespace=~"$namespace", statefulset=~"$statefulset"})',
        );

      local observedGenerationPanel =
        panel(
          title='Observed Generation',
          expr='sum(kube_statefulset_status_observed_generation{cluster=~"$cluster", namespace=~"$namespace", statefulset=~"$statefulset"})',
        );

      local metadataGenerationPanel =
        panel(
          title='Metadata Generation',
          expr='sum(kube_statefulset_metadata_generation{statefulset=~"$statefulset", cluster=~"$cluster", namespace=~"$namespace"})',
        );

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

      dashboard.new(
        'StatefulSet Detail',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sStatefulSet,
        uid=$._config.grafanaDashboards.ids.statefulSet,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(kube_statefulset_metadata_generation, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_statefulset_metadata_generation{cluster=~"$cluster"}, namespace)'),
        $.grafanaTemplates.statefulsetTemplate('label_values(kube_statefulset_metadata_generation{cluster=~"$cluster", namespace=~"$namespace"}, statefulset)'),
      ])
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
