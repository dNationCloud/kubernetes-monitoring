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

/* K8s memory namespace overview dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local table = grafana.panel.table;
local fieldOverride = grafana.panel.table.fieldOverride;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    'memory-namespace-overview':
      local memUsageGraphPanel =
        timeSeriesPanel.new('Memory Usage')
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit('bytes')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(\ncontainer_memory_working_set_bytes{cluster="$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}\n* on(namespace, pod)\ngroup_left(workload, workload_type) namespace_workload_pod:kube_pod_owner:relabel{cluster="$cluster", namespace=~"$namespace", workload=~"$workload", workload_type=~"$workload_type"}\n) by (pod) or on() sum(container_memory_working_set_bytes{cluster="$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}) by (pod)') + prometheus.withLegendFormat('{{pod}}'),
        ]);

      local nsLinkUrl = $.addRefreshParam('/d/%s?var-namespace=${__value.raw}&var-instance=${instance:text}&%s') % [$._config.grafanaDashboards.ids.containerDetail, $._config.grafanaDashboards.dataLinkCommonArgs];
      local tableTarget(expr) = prometheus.withExpr(expr) + prometheus.withFormat('table') + prometheus.withInstant(true);

      local memReqTable =
        table.new('Memory Request/Limit')
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.panelOptions.withDescription('* `Memory Request` defines sum of container memory request in selected namespace for selected node\n* `Memory Usage (only defined request)` defines memory consumption of containers with defined memory requests\n* `Memory Limit` defines sum of container memory limit in selected namespace for selected node\n* `Memory Usage (only defined limit)` defines memory consumption of containers with defined memory limits\n* `Memory Usage (total)` defines memory consumption of all pods living in selected namespace for selected node')
        + table.queryOptions.withTransformations([{ id: 'merge', options: {} }])
        + table.standardOptions.withOverrides([
          fieldOverride.byName.new('Time')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('Value #A')
          + fieldOverride.byName.withProperty('displayName', 'Pods')
          + fieldOverride.byName.withProperty('custom.width', 86),
          fieldOverride.byName.new('Value #B')
          + fieldOverride.byName.withProperty('displayName', 'Workloads')
          + fieldOverride.byName.withProperty('custom.width', 131),
          fieldOverride.byName.new('Value #C')
          + fieldOverride.byName.withProperty('displayName', 'Memory Request')
          + fieldOverride.byName.withProperty('unit', 'bytes')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 176),
          fieldOverride.byName.new('Value #D')
          + fieldOverride.byName.withProperty('displayName', 'Memory Usage (only defined request)')
          + fieldOverride.byName.withProperty('unit', 'bytes')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 365),
          fieldOverride.byName.new('Value #E')
          + fieldOverride.byName.withProperty('displayName', 'Memory Limit')
          + fieldOverride.byName.withProperty('unit', 'bytes')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 158),
          fieldOverride.byName.new('Value #F')
          + fieldOverride.byName.withProperty('displayName', 'Memory Usage (only defined limit)')
          + fieldOverride.byName.withProperty('unit', 'bytes')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 347),
          fieldOverride.byName.new('Value #G')
          + fieldOverride.byName.withProperty('displayName', 'Memory Usage (total)')
          + fieldOverride.byName.withProperty('unit', 'bytes')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 230),
          fieldOverride.byName.new('namespace')
          + fieldOverride.byName.withProperty('displayName', 'Namespace')
          + fieldOverride.byName.withProperty('links', [{ title: 'Detail', url: nsLinkUrl }]),
        ])
        + table.queryOptions.withTargets([
          tableTarget('count(sum(container_memory_working_set_bytes{cluster="$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}) by (namespace, pod)) by (namespace)'),
          tableTarget('count(avg(namespace_workload_pod:kube_pod_owner:relabel{cluster="$cluster", namespace=~"$namespace"} * on(pod, namespace) group_left(node) node_namespace_pod:kube_pod_info:{cluster="$cluster", namespace=~"$namespace", node=~"$instance"}) by (workload, namespace)) by (namespace)'),
          tableTarget('sum(kube_pod_container_resource_requests{resource="memory", cluster="$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace)'),
          tableTarget('sum by (namespace) (sum(container_memory_working_set_bytes{cluster="$cluster", node=~"$instance", container!~"POD|", id!="", namespace=~"$namespace"}) by (namespace, pod, container) * group(kube_pod_container_resource_requests{resource="memory", cluster="$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace, pod, container))'),
          tableTarget('sum(kube_pod_container_resource_limits{resource="memory", cluster="$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace)'),
          tableTarget('sum by (namespace) (sum(container_memory_working_set_bytes{cluster="$cluster", node=~"$instance", container!~"POD|", id!="", namespace=~"$namespace"}) by (namespace, pod, container) * group(kube_pod_container_resource_limits{resource="memory", cluster="$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace, pod, container))'),
          tableTarget('sum(container_memory_working_set_bytes{cluster="$cluster", node=~"$instance", container!~"POD|", id!="", namespace=~"$namespace"}) by (namespace)'),
        ]);

      dashboard.new('Memory per Namespace')
      + dashboard.withUid($._config.grafanaDashboards.ids.memoryNamespaceOverview)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sOverview)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(kube_pod_info, cluster)'),
        $.grafanaTemplates.instanceTemplate('label_values(kube_pod_info{cluster="$cluster"}, node)', label='Node'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_pod_info{cluster="$cluster", node=~"$instance"}, namespace)'),
        $.grafanaTemplates.podTemplate('label_values(kube_pod_info{cluster="$cluster", node=~"$instance", namespace=~"$namespace"}, pod)', hide='variable'),
        $.grafanaTemplates.workloadTypeTemplate('label_values(namespace_workload_pod:kube_pod_owner:relabel{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}, workload_type)'),
        $.grafanaTemplates.workloadTemplate('label_values(namespace_workload_pod:kube_pod_owner:relabel{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", workload_type=~"$workload_type"}, workload)'),
      ])
      + dashboard.withPanels([
        row.new('Memory Usage') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        memUsageGraphPanel { gridPos: { x: 0, y: 1, w: 24, h: 8 } },
        row.new('Memory Request/Limit') + { gridPos: { x: 0, y: 9, w: 24, h: 9 } },
        memReqTable { gridPos: { x: 0, y: 10, w: 24, h: 12 } },
      ]),
  },
}
