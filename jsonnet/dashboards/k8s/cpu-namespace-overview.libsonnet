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

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local row = grafana.row;
local table = grafana.tablePanel;
local graphPanel = grafana.graphPanel;

{
  grafanaDashboards+:: {
    'cpu-namespace-overview':
      local cpuUsageGraphPanel =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          stack=true,
          nullPointMode='null as zero',
          min=0,
        )
        .addTarget(
          prometheus.target(
            'sum(rate(\ncontainer_cpu_usage_seconds_total{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}[5m])\n* on(namespace, pod)\ngroup_left(workload, workload_type) namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace", workload=~"$workload", workload_type=~"$workload_type"})\nby (pod) or on() sum(rate(container_cpu_usage_seconds_total{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}[5m])) by (pod)',
            legendFormat='{{pod}}'
          ),
        );

      local cpuQuotaTable =
        table.new(
          title='CPU Request/Limit',
          description='* `CPU Request` defines sum of container cpu request in selected namespace for selected node\n* `CPU Usage (only defined request)` defines cpu consumption of containers with defined cpu requests\n* `CPU Limit` defines sum of container cpu limit in selected namespace for selected node\n* `CPU Usage (only defined limit)` defines cpu consumption of containers with defined cpu limits\n* `CPU Usage (total)` defines cpu consumption of all pods living in selected namespace for selected node',
          datasource='$datasource',
          sort={ col: 8, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Pods', pattern: 'Value #A', type: 'number' },
            { alias: 'Workloads', pattern: 'Value #B', type: 'number' },
            { alias: 'CPU Request', pattern: 'Value #C', type: 'number', decimals: 2 },
            { alias: 'CPU Usage (only defined request)', pattern: 'Value #D', type: 'number', decimals: 2 },
            { alias: 'CPU Limit', pattern: 'Value #E', type: 'number', decimals: 2 },
            { alias: 'CPU Usage (only defined limit)', pattern: 'Value #F', type: 'number', decimals: 2 },
            { alias: 'CPU Usage (total)', pattern: 'Value #G', type: 'number', decimals: 2 },
            { alias: 'Namespace', pattern: 'namespace', link: true, linkTooltip: 'Detail', linkUrl: './d/%s?var-namespace=$__cell&var-instance=${instance:text}&%s' % [$._config.grafanaDashboards.ids.containerDetail, $._config.grafanaDashboards.dataLinkCommonArgs] },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='count(sum(container_cpu_usage_seconds_total{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}) by (namespace, pod)) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='count(avg(namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace"} * on(pod) group_left(node) node_namespace_pod:kube_pod_info:{cluster=~"$cluster", namespace=~"$namespace", node=~"$instance"}) by (workload, namespace)) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='sum(kube_pod_container_resource_requests_cpu_cores{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='sum by (namespace) (sum(rate(container_cpu_usage_seconds_total{cluster=~"$cluster", container!~"POD|", id!="", node=~"$instance", namespace=~"$namespace"}[5m])) by (namespace, pod, container) * group(kube_pod_container_resource_requests_cpu_cores{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace, pod, container))'),
            prometheus.target(format='table', instant=true, expr='sum(kube_pod_container_resource_limits_cpu_cores{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='sum by (namespace) (sum(rate(container_cpu_usage_seconds_total{cluster=~"$cluster", container!~"POD|", id!="", node=~"$instance", namespace=~"$namespace"}[5m])) by (namespace, pod, container) * group(kube_pod_container_resource_limits_cpu_cores{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace, pod, container))'),
            prometheus.target(format='table', instant=true, expr='sum(rate(container_cpu_usage_seconds_total{cluster=~"$cluster", container!~"POD|", id!="", node=~"$instance", namespace=~"$namespace"}[5m])) by (namespace)'),

          ],
        );

      dashboard.new(
        title='CPU per Namespace',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.cpuNamespaceOverview,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(kube_pod_info, cluster)'),
        $.grafanaTemplates.instanceTemplate('label_values(kube_pod_info{cluster=~"$cluster"}, node)', label='Node'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_pod_info{cluster=~"$cluster", node=~"$instance"}, namespace)'),
        $.grafanaTemplates.podTemplate('label_values(kube_pod_info{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace"}, pod)', hide='variable'),
        $.grafanaTemplates.workloadTypeTemplate('label_values(namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}, workload_type)'),
        $.grafanaTemplates.workloadTemplate('label_values(namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", workload_type=~"$workload_type"}, workload)'),
      ])
      .addPanels(
        [
          row.new('CPU Usage') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          cpuUsageGraphPanel { gridPos: { x: 0, y: 1, w: 24, h: 9 }, tooltip+: { sort: 2 } },
          row.new('CPU Request/Limit') { gridPos: { x: 0, y: 10, w: 24, h: 1 } },
          cpuQuotaTable { gridPos: { x: 0, y: 11, w: 24, h: 12 } },
        ]
      ),
  },
}
