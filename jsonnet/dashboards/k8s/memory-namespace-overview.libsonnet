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

/* K8s memory namespace overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;
local graphPanel = grafana.graphPanel;

{
  grafanaDashboards+:: {
    'memory-namespace-overview.json':
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
          sort=$._config.dashboardCommon.templateSort,
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

      local memUsageGraphPanel =
        graphPanel.new(
          title='Memory Usage',
          stack=true,
          datasource='$datasource',
          format='bytes',
          min=0,
        )
        .addTarget(prometheus.target(legendFormat='{{pod}}', expr='sum(\ncontainer_memory_working_set_bytes{cluster="$cluster", namespace=~"$namespace", container!~"POD|", id!=""}\n* on(namespace, pod)\ngroup_left(workload, workload_type) namespace_workload_pod:kube_pod_owner:relabel{cluster="$cluster", namespace=~"$namespace", workload=~"$workload", workload_type=~"$type"}\n) by (pod) or on() sum(container_memory_working_set_bytes{cluster="$cluster", namespace=~"$namespace", container!~"POD|", id!=""}) by (pod)'));

      local memReqTable =
        table.new(
          title='Memory Request/Limit',
          description='* `Memory Usage` defines memory consumption of all pods living in selected namespace\n* `Memory Request` defines sum of container memory request in selected namespace\n* `Memory Request %` defines ratio between consumed memory and defined container memory request\n* `Memory Limit` defines sum of container memory limit in selected namespace\n* `Memory Limit %` defines ratio between consumed memory and defined container memory limit',
          datasource='$datasource',
          sort={ col: 4, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Pods', pattern: 'Value #A', type: 'number' },
            { alias: 'Workloads', pattern: 'Value #B', type: 'number' },
            { alias: 'Memory Usage', pattern: 'Value #C', type: 'number', unit: 'bytes', decimals: 2 },
            { alias: 'Memory Request', pattern: 'Value #D', type: 'number', unit: 'bytes', decimals: 2 },
            { alias: 'Memory Request %', pattern: 'Value #E', type: 'number', unit: 'percentunit', decimals: 2 },
            { alias: 'Memory Limit', pattern: 'Value #F', type: 'number', unit: 'bytes', decimals: 2 },
            { alias: 'Memory Limit %', pattern: 'Value #G', type: 'number', unit: 'percentunit', decimals: 2 },
            { alias: 'Namespace', pattern: 'namespace', link: true, linkTooltip: 'Drill down to pods', linkUrl: './d/%s?var-namespace=$__cell&%s' % [$._config.dashboardIDs.containerDetail, $._config.dashboardCommon.dataLinkCommonArgs] },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='count(sum(container_memory_working_set_bytes{cluster=~"$cluster", namespace=~"$namespace", container!~"POD|", id!=""}) by (namespace, pod)) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='count(avg(namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace"}) by (workload, namespace)) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='sum(container_memory_working_set_bytes{cluster=~"$cluster", container!~"POD|", id!="", namespace=~"$namespace"}) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='sum(kube_pod_container_resource_requests_memory_bytes{cluster=~"$cluster", namespace=~"$namespace"}) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='avg by (namespace) (sum(container_memory_working_set_bytes{cluster=~"$cluster", container!~"POD|", id!="", namespace=~"$namespace"}) by (namespace, pod, container) / sum(kube_pod_container_resource_requests_memory_bytes{cluster=~"$cluster", namespace=~"$namespace"}) by (namespace, pod, container))'),
            prometheus.target(format='table', instant=true, expr='sum(kube_pod_container_resource_limits_memory_bytes{cluster=~"$cluster", namespace=~"$namespace"}) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='avg by (namespace) (sum(container_memory_working_set_bytes{cluster=~"$cluster", container!~"POD|", id!="", namespace=~"$namespace"}) by (namespace, pod, container) / sum(kube_pod_container_resource_limits_memory_bytes{cluster=~"$cluster", namespace=~"$namespace"}) by (namespace, pod, container))'),
          ]
        );

      dashboard.new(
        'Memory per Namespace',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sOverview,
        uid=$._config.dashboardIDs.memoryNamespaceOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate, namespaceTemplate, workloadTemplate, workloadTypeTemplate])
      .addPanels(
        [
          row.new('Memory Usage') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          memUsageGraphPanel { gridPos: { x: 0, y: 1, w: 24, h: 8 }, tooltip+: { sort: 2 } },
          row.new('Memory Request/Limit') { gridPos: { x: 0, y: 9, w: 24, h: 9 } },
          memReqTable { gridPos: { x: 0, y: 10, w: 24, h: 12 } },
        ]
      ),
  },
}
