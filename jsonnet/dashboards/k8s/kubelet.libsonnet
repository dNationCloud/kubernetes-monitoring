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
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+::
    local kubeletDashboard(dashboardUid, dashboardName, healthTemplate) = {
      local sel = $._config.grafanaDashboards.selectors,
      local promTarget(expr, legendFormat=null) = prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {}),
      local tooltipDesc = timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc'),

      local health =
        statPanel.new('Health')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource') + statPanel.standardOptions.withUnit('percent')
        + statPanel.options.reduceOptions.withCalcs(['mean'])
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds(healthTemplate.panel.thresholds))
        + statPanel.queryOptions.withTargets([promTarget(healthTemplate.panel.expr)]),

      local timeSeriesBase(title, unit=null, min=null, desc=null, legendTable=true) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + (if min != null then timeSeriesPanel.standardOptions.withMin(min) else {})
        + (if desc != null then timeSeriesPanel.panelOptions.withDescription(desc) else {})
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + (if legendTable then timeSeriesPanel.options.legend.withDisplayMode('table') + timeSeriesPanel.options.legend.withPlacement('right') + timeSeriesPanel.options.legend.withCalcs(['lastNotNull']) else {})
        + tooltipDesc,

      local operationRate = timeSeriesBase('Operation Rate', 'ops') + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(kubelet_runtime_operations_total{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (operation_type, instance)' % sel, '{{instance}} {{operation_type}}')]),
      local operationErrorRate = timeSeriesBase('Operation Error Rate', 'ops', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(kubelet_runtime_operations_errors_total{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_type)' % sel, '{{instance}} {{operation_type}}')]),
      local operationLatency = timeSeriesBase('Operation duration 99th quantile', 's') + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.99, sum(rate(kubelet_runtime_operations_duration_seconds_bucket{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_type, le))' % sel, '{{instance}} {{operation_type}}')]),

      local podStartRate = timeSeriesBase('Pod Start Rate', 'ops', min=0) + timeSeriesPanel.queryOptions.withTargets([
        promTarget('sum(rate(kubelet_pod_start_duration_seconds_count{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance)' % sel, '{{instance}} pod'),
        promTarget('sum(rate(kubelet_pod_worker_duration_seconds_count{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance)' % sel, '{{instance}} worker'),
      ]),

      local podStartLatency = timeSeriesBase('Pod Start Duration', 's', min=0) + timeSeriesPanel.queryOptions.withTargets([
        promTarget('histogram_quantile(0.99, sum(rate(kubelet_pod_start_duration_seconds_count{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, le))' % sel, '{{instance}} pod'),
        promTarget('histogram_quantile(0.99, sum(rate(kubelet_pod_worker_duration_seconds_bucket{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, le))' % sel, '{{instance}} worker'),
      ]),

      local storageOperationRate = timeSeriesBase('Storage Operation Rate', 'ops', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(storage_operation_duration_seconds_count{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_name, volume_plugin)' % sel, '{{instance}} {{operation_name}} {{volume_plugin}}')]),
      local storageOperationErrorRate = timeSeriesBase('Storage Operation Error Rate', 'ops', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(storage_operation_duration_seconds_count{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance", status="fail-unknown"}[5m])) by (instance, operation_name, volume_plugin)' % sel, '{{instance}} {{operation_name}} {{volume_plugin}}')]),
      local storageOperationLatency = timeSeriesBase('Storage Operation Duration 99th quantile', 's', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.99, sum(rate(storage_operation_duration_seconds_bucket{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_name, volume_plugin, le))' % sel, '{{instance}} {{operation_name}} {{volume_plugin}}')]),
      local cgroupManagerRate = timeSeriesBase('Cgroup manager operation rate', 'ops', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(kubelet_cgroup_manager_duration_seconds_count{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_type)' % sel, '{{operation_type}}')]),
      local cgroupManagerDuration = timeSeriesBase('Cgroup manager 99th quantile', 's', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.99, sum(rate(kubelet_cgroup_manager_duration_seconds_bucket{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, operation_type, le))' % sel, '{{instance}} {{operation_type}}')]),
      local plegRelistRate = timeSeriesBase('PLEG relist rate', 'ops', min=0, desc='Pod lifecycle event generator') + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(kubelet_pleg_relist_duration_seconds_count{cluster="$cluster", %(kubelet)s, instance=~"$instance"}[5m])) by (instance)' % sel, '{{instance}}')]),
      local plegRelistDuration = timeSeriesBase('PLEG relist duration', 's', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.99, sum(rate(kubelet_pleg_relist_duration_seconds_bucket{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, le))' % sel, '{{instance}}')]),
      local plegRelistInterval = timeSeriesBase('PLEG relist interval', 's', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.99, sum(rate(kubelet_pleg_relist_interval_seconds_bucket{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, le))' % sel, '{{instance}}')]),

      local grpcRate = timeSeriesBase('GRPC Rate', 'reqps', min=0, legendTable=false)
                       + timeSeriesPanel.queryOptions.withTargets([
                         promTarget('sum(rate(rest_client_requests_total{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance", code=~"2.."}[5m]))' % sel, '2xx'),
                         promTarget('sum(rate(rest_client_requests_total{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance", code=~"3.."}[5m]))' % sel, '3xx'),
                         promTarget('sum(rate(rest_client_requests_total{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance", code=~"4.."}[5m]))' % sel, '4xx'),
                         promTarget('sum(rate(rest_client_requests_total{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance", code=~"5.."}[5m]))' % sel, '5xx'),
                       ]),

      local requestDuration = timeSeriesBase('Request duration 99th quantile', 's', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.99, sum(rate(rest_client_request_duration_seconds_bucket{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])) by (instance, verb, url, le))' % sel, '{{instance}} {{verb}} {{url}}')]),
      local memory = timeSeriesBase('Memory', 'bytes', legendTable=false) + timeSeriesPanel.queryOptions.withTargets([promTarget('process_resident_memory_bytes{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}' % sel, '{{instance}}')]),
      local cpu = timeSeriesBase('CPU Usage', min=0, legendTable=false) + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(process_cpu_seconds_total{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}[5m])' % sel, '{{instance}}')]),
      local goroutines = timeSeriesBase('Goroutines', legendTable=false) + timeSeriesPanel.queryOptions.withTargets([promTarget('go_goroutines{cluster="$cluster", %(kubelet)s, metrics_path="/metrics", instance=~"$instance"}' % sel, '{{instance}}')]),

      dashboard:
        dashboard.new(dashboardName)
        + dashboard.withUid($._config.grafanaDashboards.ids.kubelet)
        + dashboard.withTags($._config.grafanaDashboards.tags.k8sSystem)
        + dashboard.withEditable($._config.grafanaDashboards.editable)
        + dashboard.withRefresh($._config.grafanaDashboards.refresh)
        + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
        + $._config.grafanaDashboards.tooltip
        + dashboard.withTimezone('browser')
        + dashboard.withVariables([
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.clusterTemplate('label_values(kube_pod_info, cluster)'),
          $.grafanaTemplates.instanceTemplate('label_values(kubelet_runtime_operations_total{cluster="$cluster", %(kubelet)s, metrics_path="/metrics"}, instance)' % sel),
        ])
        + dashboard.withPanels([
          health { gridPos: { x: 0, y: 0, w: 4, h: 7 } },
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
          grpcRate { gridPos: { x: 0, y: 56, w: 24, h: 7 } },
          requestDuration { gridPos: { x: 0, y: 63, w: 24, h: 7 } },
          memory { gridPos: { x: 0, y: 70, w: 8, h: 7 } },
          cpu { gridPos: { x: 8, y: 70, w: 8, h: 7 } },
          goroutines { gridPos: { x: 16, y: 70, w: 8, h: 7 } },
        ]),
    };
    $.createControlPlaneDashboard(
      jsonName='kubelet',
      dashboardFunction=kubeletDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.kubelet,
      dashboardName='Kubelet',
      templateGroup=$._config.templates.L1.k8s,
      templateName='kubeletHealth',
    ),
}
