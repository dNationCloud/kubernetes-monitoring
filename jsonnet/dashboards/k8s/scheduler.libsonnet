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

/* K8s scheduler dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+::
    local schedulerDashboard(clusterUid, dashboardName, healthTemplate) = {
      local sel = $._config.grafanaDashboards.selectors,
      local promTarget(expr, legendFormat=null) = prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {}),

      local health =
        statPanel.new('Health')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource') + statPanel.standardOptions.withUnit('percent')
        + statPanel.options.reduceOptions.withCalcs(['mean'])
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds(healthTemplate.panel.thresholds))
        + statPanel.queryOptions.withTargets([promTarget(healthTemplate.panel.expr)]),

      local timeSeriesBase(title, unit=null, min=null, legendTable=false) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + (if min != null then timeSeriesPanel.standardOptions.withMin(min) else {})
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + (if legendTable then timeSeriesPanel.options.legend.withDisplayMode('table') + timeSeriesPanel.options.legend.withPlacement('right') + timeSeriesPanel.options.legend.withCalcs(['lastNotNull']) else {})
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc'),

      local schedulingRate = timeSeriesBase('Scheduling Rate', 'ops', min=0, legendTable=true) + timeSeriesPanel.queryOptions.withTargets([
        promTarget('sum(rate(scheduler_e2e_scheduling_duration_seconds_count{cluster="$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance)' % sel, '{{instance}} e2e'),
        promTarget('sum(rate(scheduler_binding_duration_seconds_count{cluster="$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance)' % sel, '{{instance}} binding'),
        promTarget('sum(rate(scheduler_scheduling_algorithm_duration_seconds_count{cluster="$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance)' % sel, '{{instance}} scheduling algorithm'),
        promTarget('sum(rate(scheduler_volume_scheduling_duration_seconds_count{cluster="$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance)' % sel, '{{instance}} volume'),
      ]),

      local schedulingLatency = timeSeriesBase('Scheduling latency 99th Quantile', 's', min=0, legendTable=true) + timeSeriesPanel.queryOptions.withTargets([
        promTarget('histogram_quantile(0.99, sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket{cluster="$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance, le))' % sel, '{{instance}} e2e'),
        promTarget('histogram_quantile(0.99, sum(rate(scheduler_binding_duration_seconds_bucket{cluster="$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance, le))' % sel, '{{instance}} binding'),
        promTarget('histogram_quantile(0.99, sum(rate(scheduler_scheduling_algorithm_duration_seconds_bucket{cluster="$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance, le))' % sel, '{{instance}} scheduling algorithm'),
        promTarget('histogram_quantile(0.99, sum(rate(scheduler_volume_scheduling_duration_seconds_bucket{cluster="$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance, le))' % sel, '{{instance}} volume'),
      ]),

      local grpcRate = timeSeriesBase('Kube API Request Rate', 'reqps', min=0) + timeSeriesPanel.queryOptions.withTargets([
        promTarget('sum(rate(rest_client_requests_total{cluster="$cluster", %(scheduler)s, instance=~"$instance", code=~"2.."}[5m]))' % sel, '2xx'),
        promTarget('sum(rate(rest_client_requests_total{cluster="$cluster", %(scheduler)s, instance=~"$instance", code=~"3.."}[5m]))' % sel, '3xx'),
        promTarget('sum(rate(rest_client_requests_total{cluster="$cluster", %(scheduler)s, instance=~"$instance", code=~"4.."}[5m]))' % sel, '4xx'),
        promTarget('sum(rate(rest_client_requests_total{cluster="$cluster", %(scheduler)s, instance=~"$instance", code=~"5.."}[5m]))' % sel, '5xx'),
      ]),

      local postRequestLatency = timeSeriesBase('Post Request Latency 99th Quantile', 's', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.99, sum(rate(rest_client_request_duration_seconds_bucket{cluster="$cluster", %(scheduler)s, instance=~"$instance", verb="POST"}[5m])) by (verb, url, le))' % sel, '{{verb}} {{url}}')]),
      local getRequestLatency = timeSeriesBase('Get Request Latency 99th Quantile', 's', min=0, legendTable=true) + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.99, sum(rate(rest_client_request_duration_seconds_bucket{cluster="$cluster", %(scheduler)s, instance=~"$instance", verb="GET"}[5m])) by (verb, url, le))' % sel, '{{verb}} {{url}}')]),
      local memory = timeSeriesBase('Memory', 'bytes') + timeSeriesPanel.queryOptions.withTargets([promTarget('process_resident_memory_bytes{cluster="$cluster", %(scheduler)s, instance=~"$instance"}' % sel, '{{instance}}')]),
      local cpu = timeSeriesBase('CPU Usage', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(process_cpu_seconds_total{cluster="$cluster", %(scheduler)s, instance=~"$instance"}[5m])' % sel, '{{instance}}')]),
      local goroutines = timeSeriesBase('Goroutines') + timeSeriesPanel.queryOptions.withTargets([promTarget('go_goroutines{cluster="$cluster", %(scheduler)s, instance=~"$instance"}' % sel, '{{instance}}')]),

      dashboard:
        dashboard.new(dashboardName)
        + dashboard.withUid($._config.grafanaDashboards.ids.scheduler)
        + dashboard.withTags($._config.grafanaDashboards.tags.k8sSystem)
        + dashboard.withEditable($._config.grafanaDashboards.editable)
        + dashboard.withRefresh($._config.grafanaDashboards.refresh)
        + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
        + $._config.grafanaDashboards.tooltip
        + dashboard.withTimezone('browser')
        + dashboard.withVariables([
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.clusterTemplate('label_values(scheduler_e2e_scheduling_duration_seconds_count, cluster)'),
          $.grafanaTemplates.instanceTemplate('label_values(process_cpu_seconds_total{cluster="$cluster", %(scheduler)s}, instance)' % sel),
        ])
        + dashboard.withPanels([
          health { gridPos: { x: 0, y: 0, w: 4, h: 7 } },
          schedulingRate { gridPos: { x: 4, y: 0, w: 10, h: 7 } },
          schedulingLatency { gridPos: { x: 14, y: 0, w: 10, h: 7 } },
          grpcRate { gridPos: { x: 0, y: 7, w: 8, h: 7 } },
          postRequestLatency { gridPos: { x: 8, y: 7, w: 16, h: 7 } },
          getRequestLatency { gridPos: { x: 0, y: 14, w: 24, h: 7 } },
          memory { gridPos: { x: 0, y: 21, w: 8, h: 7 } },
          cpu { gridPos: { x: 8, y: 21, w: 8, h: 7 } },
          goroutines { gridPos: { x: 16, y: 21, w: 8, h: 7 } },
        ]),
    };
    $.createControlPlaneDashboard(
      jsonName='scheduler',
      dashboardFunction=schedulerDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.scheduler,
      dashboardName='Scheduler',
      templateGroup=$._config.templates.L1.k8s,
      templateName='schedulerHealth',
    ),
}
