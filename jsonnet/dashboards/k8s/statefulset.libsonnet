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
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    statefulset:
      local sel = $._config.grafanaDashboards.selectors;

      local statBase(title, expr, unit='none') =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit(unit)
        + statPanel.options.reduceOptions.withCalcs(['mean'])
        + statPanel.queryOptions.withTargets([prometheus.withExpr(expr)]);

      local cpuPanel = statBase('CPU', 'sum(rate(container_cpu_usage_seconds_total{%(kubelet)s, metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~"$namespace", pod=~"$statefulset.*"}[5m]))' % sel, 'cores');
      local memoryPanel = statBase('Memory', 'sum(container_memory_working_set_bytes{%(kubelet)s, metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~"$namespace", pod=~"$statefulset.*", container!~"POD|", id!=""})' % sel, 'bytes');
      local networkPanel = statBase('Network', 'sum(rate(container_network_transmit_bytes_total{%(kubelet)s, metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~"$namespace", pod=~"$statefulset.*"}[5m])) + sum(rate(container_network_receive_bytes_total{cluster="$cluster", namespace=~"$namespace", pod=~"$statefulset.*"}[5m]))' % sel, 'Bps');
      local desiredReplicasPanel = statBase('Desired Replicas', 'sum(kube_statefulset_status_replicas{cluster="$cluster", namespace=~"$namespace", statefulset=~"$statefulset"})');
      local currentReplicasPanel = statBase('Replicas of current version', 'sum(kube_statefulset_status_replicas_current{cluster="$cluster", namespace=~"$namespace", statefulset=~"$statefulset"})');
      local observedGenerationPanel = statBase('Observed Generation', 'sum(kube_statefulset_status_observed_generation{cluster="$cluster", namespace=~"$namespace", statefulset=~"$statefulset"})');
      local metadataGenerationPanel = statBase('Metadata Generation', 'sum(kube_statefulset_metadata_generation{statefulset=~"$statefulset", cluster="$cluster", namespace=~"$namespace"})');

      local replicasGraphPanel =
        timeSeriesPanel.new('Replicas')
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(kube_statefulset_replicas{statefulset=~"$statefulset", cluster="$cluster", namespace=~"$namespace"}) by (statefulset)') + prometheus.withLegendFormat('replicas specified {{statefulset}}'),
          prometheus.withExpr('sum(kube_statefulset_status_replicas{statefulset=~"$statefulset", cluster="$cluster", namespace=~"$namespace"}) by (statefulset)') + prometheus.withLegendFormat('replicas created {{statefulset}}'),
          prometheus.withExpr('sum(kube_statefulset_status_replicas_ready{statefulset=~"$statefulset", cluster="$cluster", namespace=~"$namespace"}) by (statefulset)') + prometheus.withLegendFormat('ready {{statefulset}}'),
          prometheus.withExpr('sum(kube_statefulset_status_replicas_current{statefulset=~"$statefulset", cluster="$cluster", namespace=~"$namespace"}) by (statefulset)') + prometheus.withLegendFormat('replicas of current version {{statefulset}}'),
          prometheus.withExpr('sum(kube_statefulset_status_replicas_updated{statefulset=~"$statefulset", cluster="$cluster", namespace=~"$namespace"}) by (statefulset)') + prometheus.withLegendFormat('updated {{statefulset}}'),
        ]);

      dashboard.new('StatefulSet Detail')
      + dashboard.withUid($._config.grafanaDashboards.ids.statefulSet)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sStatefulSet)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(kube_statefulset_metadata_generation, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_statefulset_metadata_generation{cluster="$cluster"}, namespace)'),
        $.grafanaTemplates.statefulsetTemplate('label_values(kube_statefulset_metadata_generation{cluster="$cluster", namespace=~"$namespace"}, statefulset)'),
      ])
      + dashboard.withPanels([
        cpuPanel { gridPos: { x: 0, y: 0, w: 8, h: 7 } },
        memoryPanel { gridPos: { x: 8, y: 0, w: 8, h: 7 } },
        networkPanel { gridPos: { x: 16, y: 0, w: 8, h: 7 } },
        desiredReplicasPanel { gridPos: { x: 0, y: 7, w: 6, h: 3 } },
        currentReplicasPanel { gridPos: { x: 6, y: 7, w: 6, h: 3 } },
        observedGenerationPanel { gridPos: { x: 12, y: 7, w: 6, h: 3 } },
        metadataGenerationPanel { gridPos: { x: 18, y: 7, w: 6, h: 3 } },
        replicasGraphPanel { gridPos: { x: 0, y: 10, w: 24, h: 7 } },
      ]),
  },
}
