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

/* K8s kubelet dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;

{
  grafanaDashboards+:: {
    kubelet:
      local upCount =
        statPanel.new(
          title='Up',
          datasource='$datasource',
        )
        .addThresholds($.grafanaThresholds($._config.thresholds.controlPlane))
        .addTarget(prometheus.target('sum(up{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics"})' % $._config.dashboardSelectors));

      local operationRate =
        graphPanel.new(
          title='Operation Rate',
          datasource='$datasource',
          format='ops',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('sum(rate(kubelet_runtime_operations_total{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (operation_type, instance)' % $._config.dashboardSelectors, legendFormat='{{instance}} {{operation_type}}'));

      local operationErrorRate =
        graphPanel.new(
          title='Operation Error Rate',
          datasource='$datasource',
          format='ops',
          min=0,
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('sum(rate(kubelet_runtime_operations_errors_total{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_type)' % $._config.dashboardSelectors, legendFormat='{{instance}} {{operation_type}}'));

      local operationLatency =
        graphPanel.new(
          title='Operation duration 99th quantile',
          datasource='$datasource',
          format='s',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(kubelet_runtime_operations_duration_seconds_bucket{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_type, le))' % $._config.dashboardSelectors, legendFormat='{{instance}} {{operation_type}}'));

      local podStartRate =
        graphPanel.new(
          title='Pod Start Rate',
          datasource='$datasource',
          format='ops',
          min=0,
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(kubelet_pod_start_duration_seconds_count{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance)' % $._config.dashboardSelectors, legendFormat='{{instance}} pod'),
            prometheus.target('sum(rate(kubelet_pod_worker_duration_seconds_count{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance)' % $._config.dashboardSelectors, legendFormat='{{instance}} worker'),
          ]
        );

      local podStartLatency =
        graphPanel.new(
          title='Pod Start Duration',
          datasource='$datasource',
          format='s',
          min=0,
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTargets(
          [
            prometheus.target('histogram_quantile(0.99, sum(rate(kubelet_pod_start_duration_seconds_count{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, le))' % $._config.dashboardSelectors, legendFormat='{{instance}} pod'),
            prometheus.target('histogram_quantile(0.99, sum(rate(kubelet_pod_worker_duration_seconds_bucket{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, le))' % $._config.dashboardSelectors, legendFormat='{{instance}} worker'),
          ]
        );

      local storageOperationRate =
        graphPanel.new(
          title='Storage Operation Rate',
          datasource='$datasource',
          format='ops',
          min=0,
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
          legend_hideEmpty=true,
          legend_hideZero=true,
        )
        .addTarget(prometheus.target('sum(rate(storage_operation_duration_seconds_count{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_name, volume_plugin)' % $._config.dashboardSelectors, legendFormat='{{instance}} {{operation_name}} {{volume_plugin}}'));

      local storageOperationErrorRate =
        graphPanel.new(
          title='Storage Operation Error Rate',
          datasource='$datasource',
          format='ops',
          min=0,
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
          legend_hideEmpty=true,
          legend_hideZero=true,
        )
        .addTarget(prometheus.target('sum(rate(storage_operation_errors_total{cluster=~"$cluster", %(kubelet)s, instance=~"$instance"}[5m])) by (instance, operation_name, volume_plugin)' % $._config.dashboardSelectors, legendFormat='{{instance}} {{operation_name}} {{volume_plugin}}'));

      local storageOperationLatency =
        graphPanel.new(
          title='Storage Operation Duration 99th quantile',
          datasource='$datasource',
          min=0,
          format='s',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
          legend_hideEmpty=true,
          legend_hideZero=true,
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(storage_operation_duration_seconds_bucket{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_name, volume_plugin, le))' % $._config.dashboardSelectors, legendFormat='{{instance}} {{operation_name}} {{volume_plugin}}'));

      local cgroupManagerRate =
        graphPanel.new(
          title='Cgroup manager operation rate',
          datasource='$datasource',
          min=0,
          format='ops',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('sum(rate(kubelet_cgroup_manager_duration_seconds_count{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_type)' % $._config.dashboardSelectors, legendFormat='{{operation_type}}'));

      local cgroupManagerDuration =
        graphPanel.new(
          title='Cgroup manager 99th quantile',
          datasource='$datasource',
          min=0,
          format='s',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(kubelet_cgroup_manager_duration_seconds_bucket{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_type, le))' % $._config.dashboardSelectors, legendFormat='{{instance}} {{operation_type}}'));

      local plegRelistRate =
        graphPanel.new(
          title='PLEG relist rate',
          datasource='$datasource',
          description='Pod lifecycle event generator',
          min=0,
          format='ops',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('sum(rate(kubelet_pleg_relist_duration_seconds_count{cluster=~"$cluster", %(kubelet)s, instance=~"$instance"}[5m])) by (instance)' % $._config.dashboardSelectors, legendFormat='{{instance}}'));

      local plegRelistDuration =
        graphPanel.new(
          title='PLEG relist duration',
          datasource='$datasource',
          min=0,
          format='s',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(kubelet_pleg_relist_duration_seconds_bucket{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, le))' % $._config.dashboardSelectors, legendFormat='{{instance}}'));

      local plegRelistInterval =
        graphPanel.new(
          title='PLEG relist interval',
          datasource='$datasource',
          min=0,
          format='s',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(kubelet_pleg_relist_interval_seconds_bucket{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, le))' % $._config.dashboardSelectors, legendFormat='{{instance}}'));

      local rpcRate =
        graphPanel.new(
          title='RPC Rate',
          datasource='$datasource',
          min=0,
          format='reqps',
        )
        .addTargets(
          [
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance", code=~"2.."}[5m]))' % $._config.dashboardSelectors, legendFormat='2xx'),
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance", code=~"3.."}[5m]))' % $._config.dashboardSelectors, legendFormat='3xx'),
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance", code=~"4.."}[5m]))' % $._config.dashboardSelectors, legendFormat='4xx'),
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance", code=~"5.."}[5m]))' % $._config.dashboardSelectors, legendFormat='5xx'),
          ]
        );

      local requestDuration =
        graphPanel.new(
          title='Request duration 99th quantile',
          datasource='$datasource',
          min=0,
          format='s',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(rest_client_request_duration_seconds_bucket{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, verb, url, le))' % $._config.dashboardSelectors, legendFormat='{{instance}} {{verb}} {{url}}'));

      local memory =
        graphPanel.new(
          title='Memory',
          datasource='$datasource',
          format='bytes',
        )
        .addTarget(prometheus.target('process_resident_memory_bytes{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}' % $._config.dashboardSelectors, legendFormat='{{instance}}'));

      local cpu =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          min=0,
        )
        .addTarget(prometheus.target('rate(process_cpu_seconds_total{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])' % $._config.dashboardSelectors, legendFormat='{{instance}}'));

      local goroutines =
        graphPanel.new(
          title='Goroutines',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('go_goroutines{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}' % $._config.dashboardSelectors, legendFormat='{{instance}}'));

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
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local instanceTemplate =
        template.new(
          name='instance',
          label='Instance',
          datasource='$datasource',
          query='label_values(kubelet_runtime_operations_total{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics"}, instance)' % $._config.dashboardSelectors,
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          includeAll=true,
          multi=true,
        );

      dashboard.new(
        'Kubelet',
        time_from=$._config.dashboardCommon.time_from,
        uid=$._config.dashboardIDs.kubelet,
        editable=$._config.dashboardCommon.editable,
        tags=$._config.dashboardCommon.tags.k8sSystem,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
      )
      .addTemplates([datasourceTemplate, clusterTemplate, instanceTemplate])
      .addPanels(
        [
          upCount { gridPos: { x: 0, y: 0, w: 4, h: 7 } },
          operationRate { gridPos: { x: 4, y: 0, w: 10, h: 7 } },
          operationErrorRate { gridPos: { x: 14, y: 0, w: 10, h: 7 } },
          operationLatency { gridPos: { x: 0, y: 7, w: 24, h: 7 } },
          podStartRate { gridPos: { x: 0, y: 14, w: 12, h: 7 } },
          podStartLatency { gridPos: { x: 12, y: 14, w: 12, h: 7 } },
          storageOperationRate { gridPos: { x: 0, y: 21, w: 12, h: 7 } },
          storageOperationErrorRate { gridPos: { x: 12, y: 21, w: 12, h: 7 } },
          storageOperationLatency { gridPos: { x: 0, y: 28, w: 24, h: 7 } },
          cgroupManagerRate { gridPos: { x: 0, y: 35, w: 12, h: 7 } },
          cgroupManagerDuration { gridPos: { x: 12, y: 35, w: 12, h: 7 } },
          plegRelistRate { gridPos: { x: 0, y: 42, w: 12, h: 7 } },
          plegRelistInterval { gridPos: { x: 12, y: 42, w: 12, h: 7 } },
          plegRelistDuration { gridPos: { x: 0, y: 49, w: 24, h: 7 } },
          rpcRate { gridPos: { x: 0, y: 56, w: 24, h: 7 } },
          requestDuration { gridPos: { x: 0, y: 63, w: 24, h: 7 } },
          memory { gridPos: { x: 0, y: 70, w: 8, h: 7 } },
          cpu { gridPos: { x: 8, y: 70, w: 8, h: 7 } },
          goroutines { gridPos: { x: 16, y: 70, w: 8, h: 7 } },
        ]
      ),
  },
}
