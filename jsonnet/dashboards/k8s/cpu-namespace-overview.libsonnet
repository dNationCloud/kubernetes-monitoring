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

/* K8s cpu namespace overview dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local table = grafana.panel.table;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;
local fieldOverride = grafana.panel.table.fieldOverride;

{
  grafanaDashboards+:: {
    'cpu-namespace-overview':
      local cpuUsageGraphPanel =
        timeSeriesPanel.new('CPU Usage')
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc')
        + timeSeriesPanel.queryOptions.withTargets([
          prometheus.withExpr('sum(rate(\ncontainer_cpu_usage_seconds_total{cluster="$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}[5m])\n* on(namespace, pod)\ngroup_left(workload, workload_type) namespace_workload_pod:kube_pod_owner:relabel{cluster="$cluster", namespace=~"$namespace", workload=~"$workload", workload_type=~"$workload_type"})\nby (pod) or on() sum(rate(container_cpu_usage_seconds_total{cluster="$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}[5m])) by (pod)') + prometheus.withLegendFormat('{{pod}}'),
        ]);

      local nsLinkUrl = $.addRefreshParam('/d/%s?var-namespace=$__cell&var-instance=${instance:text}&%s') % [$._config.grafanaDashboards.ids.containerDetail, $._config.grafanaDashboards.dataLinkCommonArgs];
      local tableTarget(expr) = prometheus.withExpr(expr) + prometheus.withFormat('table') + prometheus.withInstant(true);

      local cpuQuotaTable =
        table.new('CPU Request/Limit')
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.panelOptions.withDescription('* `CPU Request` defines sum of container cpu request in selected namespace for selected node\n* `CPU Usage (only defined request)` defines cpu consumption of containers with defined cpu requests\n* `CPU Limit` defines sum of container cpu limit in selected namespace for selected node\n* `CPU Usage (only defined limit)` defines cpu consumption of containers with defined cpu limits\n* `CPU Usage (total)` defines cpu consumption of all pods living in selected namespace for selected node')
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
          + fieldOverride.byName.withProperty('displayName', 'CPU Request')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 149),
          fieldOverride.byName.new('Value #D')
          + fieldOverride.byName.withProperty('displayName', 'CPU Usage (only defined request)')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 338),
          fieldOverride.byName.new('Value #E')
          + fieldOverride.byName.withProperty('displayName', 'CPU Limit')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 131),
          fieldOverride.byName.new('Value #F')
          + fieldOverride.byName.withProperty('displayName', 'CPU Usage (only defined limit)')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 320),
          fieldOverride.byName.new('Value #G')
          + fieldOverride.byName.withProperty('displayName', 'CPU Usage (total)')
          + fieldOverride.byName.withProperty('decimals', 2)
          + fieldOverride.byName.withProperty('custom.width', 203),
          fieldOverride.byName.new('namespace')
          + fieldOverride.byName.withProperty('displayName', 'Namespace')
          + fieldOverride.byName.withProperty('links', [{ title: 'Detail', url: nsLinkUrl }]),
        ])
        + table.queryOptions.withTargets([
          tableTarget('count(sum(container_cpu_usage_seconds_total{cluster="$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}) by (namespace, pod)) by (namespace)'),
          tableTarget('count(avg(namespace_workload_pod:kube_pod_owner:relabel{cluster="$cluster", namespace=~"$namespace"} * on(pod, namespace) group_left(node) node_namespace_pod:kube_pod_info:{cluster="$cluster", namespace=~"$namespace", node=~"$instance"}) by (workload, namespace)) by (namespace)'),
          tableTarget('sum(kube_pod_container_resource_requests{resource="cpu", cluster="$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace)'),
          tableTarget('sum by (namespace) (sum(rate(container_cpu_usage_seconds_total{cluster="$cluster", container!~"POD|", id!="", node=~"$instance", namespace=~"$namespace"}[5m])) by (namespace, pod, container) * group(kube_pod_container_resource_requests{resource="cpu", cluster="$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace, pod, container))'),
          tableTarget('sum(kube_pod_container_resource_limits{resource="cpu", cluster="$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace)'),
          tableTarget('sum by (namespace) (sum(rate(container_cpu_usage_seconds_total{cluster="$cluster", container!~"POD|", id!="", node=~"$instance", namespace=~"$namespace"}[5m])) by (namespace, pod, container) * group(kube_pod_container_resource_limits{resource="cpu", cluster="$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace, pod, container))'),
          tableTarget('sum(rate(container_cpu_usage_seconds_total{cluster="$cluster", container!~"POD|", id!="", node=~"$instance", namespace=~"$namespace"}[5m])) by (namespace)'),
        ]);

      dashboard.new('CPU per Namespace')
      + dashboard.withUid($._config.grafanaDashboards.ids.cpuNamespaceOverview)
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
        row.new('CPU Usage') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        cpuUsageGraphPanel { gridPos: { x: 0, y: 1, w: 24, h: 9 } },
        row.new('CPU Request/Limit') + { gridPos: { x: 0, y: 10, w: 24, h: 1 } },
        cpuQuotaTable { gridPos: { x: 0, y: 11, w: 24, h: 12 } },
      ]),
  },
}
