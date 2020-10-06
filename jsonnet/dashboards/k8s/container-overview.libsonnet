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

/* K8s container overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;

local sumArr(arr) =
  /**
   * Compute sum of array elements.
   *
   * @param arrays The input array.
   * @return sum as number.
   */
  std.foldl(function(x, y) x + y, arr, 0);

local getNextIndex(arrays) =
  /**
   * Compute index (starting from 1) which would have new element
   * in array made by concatenating input arrays.
   *
   * @param arrays The input array of arrays.
   * @return next index as number.
   */
  sumArr([std.length(arr) for arr in arrays]) + 1;

{
  grafanaDashboards+:: {
    'container-overview.json':
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
          query='label_values(kube_pod_container_info{cluster=~"$cluster"}, cluster)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local colors = [$._config.dashboardCommon.color.green, $._config.dashboardCommon.color.orange, $._config.dashboardCommon.color.red];

      local waitingErrors = ['CrashLoopBackOff', 'CreateContainerConfigError', 'ErrImagePull', 'ImagePullBackOff', 'CreateContainerError', 'InvalidImageName', 'CrashLoopBackOff'];
      local terminatedErrors = ['OOMKilled', 'Error', 'ContainerCannotRun', 'DeadlineExceeded', 'Evicted'];

      local valueMapsOk = [
        { text: 'Terminated (Completed)', value: 1 },
        { text: 'Running', value: 2 },
        { text: 'Waiting (ContainerCreating)', value: 3 },
      ];
      local writingErrorsValues = [{ err: waitingErrors[i], value: getNextIndex([valueMapsOk]) + i } for i in std.range(0, std.length(waitingErrors) - 1)];
      local terminatedErrorsValues = [{ err: terminatedErrors[i], value: getNextIndex([valueMapsOk, writingErrorsValues]) + i } for i in std.range(0, std.length(terminatedErrors) - 1)];

      local valueMapsWaitingErrors = [{ text: 'Waiting (%s)' % map.err, value: map.value } for map in writingErrorsValues];
      local valueMapsTerminatedErrors = [{ text: 'Terminated (%s)' % map.err, value: map.value } for map in terminatedErrorsValues];
      local valueMaps = std.flattenArrays([valueMapsOk, valueMapsWaitingErrors, valueMapsTerminatedErrors]);

      local okQueries = [
        'sum by (container, namespace, pod) (kube_pod_container_status_terminated_reason{cluster=~"$cluster", reason="Completed"} * 1)',
        'sum by (container, namespace, pod) (kube_pod_container_status_running{cluster=~"$cluster"} * 2)',
        'sum by (container, namespace, pod) (kube_pod_container_status_waiting_reason{cluster=~"$cluster", reason="ContainerCreating"} * 3)',
      ];
      local waitingErrorsQueries = ['sum by (container, namespace, pod) (kube_pod_container_status_waiting_reason{cluster=~"$cluster", reason="%(err)s"} * %(value)d)' % map for map in writingErrorsValues];
      local terminatedErrorsQueries = ['sum by (container, namespace, pod) (kube_pod_container_status_terminated_reason{cluster=~"$cluster", reason="%(err)s"} * %(value)d)' % map for map in terminatedErrorsValues];
      local statusExpr = std.join(' + \n', std.flattenArrays([okQueries, waitingErrorsQueries, terminatedErrorsQueries]));

      local containersTable =
        table.new(
          title='Containers',
          datasource='$datasource',
          sort={ col: 4, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Status', pattern: 'Value #A', type: 'string', mappingType: 1, valueMaps: valueMaps, thresholds: [4, 4], colorMode: 'cell', colors: colors },
            { alias: 'Restarts', pattern: 'Value #B', type: 'number', thresholds: [5, 10], colorMode: 'cell', colors: colors },
            { alias: 'Container', pattern: 'container', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-container=${__cell_1}&var-namespace=${__cell_2}&var-pod=${__cell_3}&var-view=container&var-search=&%s' % [$._config.dashboardIDs.containerDetail, $._config.dashboardCommon.dataLinkCommonArgs] },
            { alias: 'Namespace', pattern: 'namespace', type: 'string' },
            { alias: 'Pod', pattern: 'pod', type: 'string' },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr=statusExpr),
            prometheus.target(format='table', instant=true, expr='sum by (container, namespace, pod) (kube_pod_container_status_restarts_total{cluster=~"$cluster"})'),
          ]
        );

      dashboard.new(
        'Container',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sOverview,
        uid=$._config.dashboardIDs.containerOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate])
      .addPanels(
        [
          row.new('Containers') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          containersTable { gridPos: { x: 0, y: 1, w: 24, h: 26 } },
        ]
      ),
  },
}
