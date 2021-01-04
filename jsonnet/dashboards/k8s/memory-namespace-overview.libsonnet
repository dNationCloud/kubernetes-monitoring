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

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;
local graphPanel = grafana.graphPanel;

{
  grafanaDashboards+:: {
    'memory-namespace-overview':
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
          query='label_values(kube_pod_info, cluster)',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      local instanceTemplate =
        template.new(
          name='instance',
          label='Node',
          query='label_values(kube_pod_info{cluster=~"$cluster"}, node)',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          multi=true,
          includeAll=true,
        );

      local namespaceTemplate =
        template.new(
          name='namespace',
          label='Namespace',
          datasource='$datasource',
          query='label_values(kube_pod_info{cluster=~"$cluster", node=~"$instance"}, namespace)',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          multi=true,
          includeAll=true,
        );

      local workloadTemplate =
        template.new(
          name='workload',
          label='Workload',
          datasource='$datasource',
          query='label_values(namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", workload_type=~"$workload_type"}, workload)',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          multi=true,
          includeAll=true,
        );

      local workloadTypeTemplate =
        template.new(
          name='workload_type',
          label='Workload Type',
          datasource='$datasource',
          query='label_values(namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}, workload_type)',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          multi=true,
          includeAll=true,
          allValues='workaround',  // workaround for pods without workload type
        );

      local podTemplate =
        template.new(
          name='pod',
          label='Pod',
          datasource='$datasource',
          query='label_values(kube_pod_info{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace"}, pod)',
          refresh=$._config.grafanaDashboards.templateRefresh,
          sort=$._config.grafanaDashboards.templateSort,
          includeAll=true,
          multi=true,
          hide='variable',
        );

      local memUsageGraphPanel =
        graphPanel.new(
          title='Memory Usage',
          stack=true,
          datasource='$datasource',
          format='bytes',
          min=0,
        )
        .addTarget(prometheus.target(legendFormat='{{pod}}', expr='sum(\ncontainer_memory_working_set_bytes{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}\n* on(namespace, pod)\ngroup_left(workload, workload_type) namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace", workload=~"$workload", workload_type=~"$workload_type"}\n) by (pod) or on() sum(container_memory_working_set_bytes{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}) by (pod)'));

      local memReqTable =
        table.new(
          title='Memory Request/Limit',
          description='* `Memory Request` defines sum of container memory request in selected namespace for selected node\n* `Memory Usage (only defined request)` defines memory consumption of containers with defined memory requests\n* `Memory Limit` defines sum of container memory limit in selected namespace for selected node\n* `Memory Usage (only defined limit)` defines memory consumption of containers with defined memory limits\n* `Memory Usage (total)` defines memory consumption of all pods living in selected namespace for selected node',
          datasource='$datasource',
          sort={ col: 8, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Pods', pattern: 'Value #A', type: 'number' },
            { alias: 'Workloads', pattern: 'Value #B', type: 'number' },
            { alias: 'Memory Request', pattern: 'Value #C', type: 'number', unit: 'bytes', decimals: 2 },
            { alias: 'Memory Usage (only defined request)', pattern: 'Value #D', type: 'number', unit: 'bytes', decimals: 2 },
            { alias: 'Memory Limit', pattern: 'Value #E', type: 'number', unit: 'bytes', decimals: 2 },
            { alias: 'Memory Usage (only defined limit)', pattern: 'Value #F', type: 'number', unit: 'bytes', decimals: 2 },
            { alias: 'Memory Usage (total)', pattern: 'Value #G', type: 'number', unit: 'bytes', decimals: 2 },
            { alias: 'Namespace', pattern: 'namespace', link: true, linkTooltip: 'Detail', linkUrl: './d/%s?var-namespace=$__cell&var-instance=${instance:text}&%s' % [$._config.grafanaDashboards.ids.containerDetail, $._config.grafanaDashboards.dataLinkCommonArgs] },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='count(sum(container_memory_working_set_bytes{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace", container!~"POD|", id!=""}) by (namespace, pod)) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='count(avg(namespace_workload_pod:kube_pod_owner:relabel{cluster=~"$cluster", namespace=~"$namespace"} * on(pod) group_left(node) node_namespace_pod:kube_pod_info:{cluster=~"$cluster", namespace=~"$namespace", node=~"$instance"}) by (workload, namespace)) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='sum(kube_pod_container_resource_requests_memory_bytes{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='sum by (namespace) (sum(container_memory_working_set_bytes{cluster=~"$cluster", node=~"$instance", container!~"POD|", id!="", namespace=~"$namespace"}) by (namespace, pod, container) * group(kube_pod_container_resource_requests_memory_bytes{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace, pod, container))'),
            prometheus.target(format='table', instant=true, expr='sum(kube_pod_container_resource_limits_memory_bytes{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace)'),
            prometheus.target(format='table', instant=true, expr='sum by (namespace) (sum(container_memory_working_set_bytes{cluster=~"$cluster", node=~"$instance", container!~"POD|", id!="", namespace=~"$namespace"}) by (namespace, pod, container) * group(kube_pod_container_resource_limits_memory_bytes{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace"}) by (namespace, pod, container))'),
            prometheus.target(format='table', instant=true, expr='sum(container_memory_working_set_bytes{cluster=~"$cluster", node=~"$instance", container!~"POD|", id!="", namespace=~"$namespace"}) by (namespace)'),
          ]
        );

      dashboard.new(
        'Memory per Namespace',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.memoryNamespaceOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate, instanceTemplate, namespaceTemplate, workloadTypeTemplate, workloadTemplate, podTemplate])
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
