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

/* K8s cpu namespace overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;
local graphPanel = grafana.graphPanel;

{
  grafanaDashboards+:: {
    'cpu-namespace-overview.json':
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
          query='label_values(node_cpu_seconds_total, cluster)',
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local namespaceTemplate =
        template.new(
          name='namespace',
          label='Namespace',
          datasource='$datasource',
          query='label_values(kube_pod_info{cluster=~"$cluster"}, namespace)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          multi=true,
          includeAll=true,
        );

      local workloadTemplate =
        template.new(
          name='workload',
          label='Workload',
          datasource='$datasource',
          query='label_values(namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace"}, workload)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          multi=true,
          includeAll=true,
          allValues='workaround',  // workaround for pods without workload
        );

      local workloadTypeTemplate =
        template.new(
          name='type',
          label='Type',
          datasource='$datasource',
          query='label_values(namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace", workload=~"$workload"}, workload_type)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          multi=true,
          includeAll=true,
        );

      local cpuUsageGraphPanel =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          stack=true,
          min=0,
        )
        .addTarget(
          prometheus.target(
            expr='sum(rate(\ncontainer_cpu_usage_seconds_total{cluster="$cluster", namespace=~"$namespace", container!~"POD|", id!=""}[5m])\n* on(namespace, pod)\ngroup_left(workload, workload_type) namespace_workload_pod:kube_pod_owner:relabel{cluster="$cluster", namespace=~"$namespace", workload=~"$workload", workload_type=~"$type"})\nby (pod) or on() sum(rate(container_cpu_usage_seconds_total{cluster="$cluster", namespace=~"$namespace", container!~"POD|", id!=""}[5m])) by (pod)',
            legendFormat='{{pod}}'
          ),
        );

      local cpuQuotaTable =
        table.new(
          title='CPU Request/Limit',
          description='* `CPU Usage` defines cpu consumption of all pods living in selected namespace\n* `CPU Request` defines sum of container cpu request in selected namespace\n* `CPU Request %` defines ratio between consumed cpu and defined container cpu request\n* `CPU Limit` defines sum of container cpu limit in selected namespace\n* `CPU Limit %` defines ratio between consumed cpu and defined container cpu limit',
          datasource='$datasource',
          sort={ col: 4, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Pods', pattern: 'Value #A', type: 'number' },
            { alias: 'Workloads', pattern: 'Value #B', type: 'number' },
            { alias: 'CPU Usage', pattern: 'Value #C', type: 'number', decimals: 2 },
            { alias: 'CPU Request', pattern: 'Value #D', type: 'number', decimals: 2 },
            { alias: 'CPU Request %', pattern: 'Value #E', type: 'number', unit: 'percentunit', decimals: 2 },
            { alias: 'CPU Limit', pattern: 'Value #F', type: 'number', decimals: 2 },
            { alias: 'CPU Limit %', pattern: 'Value #G', type: 'number', unit: 'percentunit', decimals: 2 },
            { alias: 'Namespace', pattern: 'namespace', link: true, linkTooltip: 'Drill down to pods', linkUrl: './d/%s?var-namespace=$__cell&%s' % [$._config.dashboardIDs.containerDetail, $._config.dashboardCommon.dataLinkCommonArgs] },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='count(sum(container_cpu_usage_seconds_total{cluster=~"$cluster", namespace=~"$namespace", container!~"POD|", id!=""}) by (namespace, pod)) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='count(avg(namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace"}) by (workload, namespace)) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='sum(rate(container_cpu_usage_seconds_total{cluster=~"$cluster", container!~"POD|", id!="", namespace=~"$namespace"}[5m])) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='sum(kube_pod_container_resource_requests_cpu_cores{cluster=~"$cluster", namespace=~"$namespace"}) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='avg by (namespace) (sum(rate(container_cpu_usage_seconds_total{cluster=~"$cluster", container!~"POD|", id!="",namespace=~"$namespace"}[5m])) by (namespace, pod, container) / sum(kube_pod_container_resource_requests_cpu_cores{cluster=~"$cluster", namespace=~"$namespace"}) by (namespace, pod, container))'),
            prometheus.target(format='table', instant=true, expr='sum(kube_pod_container_resource_limits_cpu_cores{cluster=~"$cluster", namespace=~"$namespace"}) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='avg by (namespace) (sum(rate(container_cpu_usage_seconds_total{cluster=~"$cluster", container!~"POD|", id!="", namespace=~"$namespace"}[5m])) by (namespace, pod, container) / sum(kube_pod_container_resource_limits_cpu_cores{cluster=~"$cluster", namespace=~"$namespace"}) by (namespace, pod, container))'),
          ],
        );

      dashboard.new(
        title='CPU per Namespace',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sOverview,
        uid=$._config.dashboardIDs.cpuNamespaceOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate, namespaceTemplate, workloadTemplate, workloadTypeTemplate])
      .addPanels(
        [
          row.new('CPU') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          cpuUsageGraphPanel { gridPos: { x: 0, y: 1, w: 24, h: 9 }, tooltip+: { sort: 2 } },
          row.new('CPU Quota') { gridPos: { x: 0, y: 10, w: 24, h: 1 } },
          cpuQuotaTable { gridPos: { x: 0, y: 11, w: 24, h: 12 } },
        ]
      ),
  },
}
