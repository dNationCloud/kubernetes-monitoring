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

/* K8s api server dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local prometheus = grafana.query.prometheus;
local fieldOverride = grafana.panel.timeSeries.fieldOverride;
local availabilityDays = 30;
local errorBudgetTarget = 0.99;

{
  grafanaDashboards+::
    local apiServerDashboard(dashboardUid, dashboardName, healthTemplate) = {
      local sel = $._config.grafanaDashboards.selectors,
      local promTarget(expr, legendFormat=null) = prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {}),

      local color(alias, col) = fieldOverride.byRegexp.new(alias)
                                + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: col }),

      local statBase(title, expr, unit, thresholds=null) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit(unit)
        + statPanel.options.reduceOptions.withCalcs(['mean'])
        + (if thresholds != null then statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps(thresholds) else {})
        + statPanel.queryOptions.withTargets([promTarget(expr)]),

      local timeSeriesBase(title, unit=null, min=null, stack=false, showLegend=true, legendTable=false, overrides=[]) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + (if min != null then timeSeriesPanel.standardOptions.withMin(min) else {})
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + (if stack then timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' }) + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false) else {})
        + (if !showLegend then timeSeriesPanel.options.legend.withShowLegend(false) else {})
        + (if legendTable then timeSeriesPanel.options.legend.withDisplayMode('table') + timeSeriesPanel.options.legend.withPlacement('right') + timeSeriesPanel.options.legend.withCalcs(['lastNotNull']) else {})
        + (if std.length(overrides) > 0 then timeSeriesPanel.standardOptions.withOverrides(overrides) else {})
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc'),

      local codeOverrides = [color('/2../i', '#56A64B'), color('/3../i', '#F2CC0C'), color('/4../i', '#3274D9'), color('/5../i', '#E02F44')],
      local availability1d = statBase('Availability (%dd) > %.3f%%' % [availabilityDays, 100 * errorBudgetTarget], 'apiserver_request:availability%dd{cluster="$cluster", verb="all"}' % availabilityDays, 'percentunit'),
      local errorBudget = timeSeriesBase('ErrorBudget (%dd) > %.3f%%' % [availabilityDays, 100 * errorBudgetTarget], 'percentunit') + timeSeriesPanel.queryOptions.withTargets([promTarget('100 * (apiserver_request:availability%dd{cluster="$cluster", verb="all"} - %f)' % [availabilityDays, errorBudgetTarget], 'errorbudget')]),
      local readAvailability = statBase('Read Availability (%dd)' % availabilityDays, 'apiserver_request:availability%dd{cluster="$cluster", verb="read"}' % availabilityDays, 'percentunit'),
      local readRequests = timeSeriesBase('Read SLI - Requests', 'reqps', stack=true, overrides=codeOverrides) + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(code_resource:apiserver_request_total:rate5m{cluster="$cluster", verb="read"})', '{{code}}')]),
      local readErrors = timeSeriesBase('Read SLI - Errors', 'percentunit', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('sum by (resource) (code_resource:apiserver_request_total:rate5m{cluster="$cluster", verb="read", code=~"5.."}) / sum by (resource) (code_resource:apiserver_request_total:rate5m{cluster="$cluster", verb="read"})', '{{resource}}')]),
      local readDuration = timeSeriesBase('Read SLI - Duration', 's') + timeSeriesPanel.queryOptions.withTargets([promTarget('cluster_quantile:apiserver_request_sli_duration_seconds:histogram_quantile{cluster="$cluster", verb="read"}', '{{resource}}')]),
      local writeAvailability = statBase('Write Availability (%dd)' % availabilityDays, 'apiserver_request:availability%dd{cluster="$cluster", verb="write"}' % availabilityDays, 'percentunit'),
      local writeRequests = timeSeriesBase('Write SLI - Requests', 'reqps', stack=true, overrides=codeOverrides) + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(code_resource:apiserver_request_total:rate5m{cluster="$cluster", verb="write"})', '{{code}}')]),
      local writeErrors = timeSeriesBase('Write SLI - Errors', 'percentunit', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('sum by (resource) (code_resource:apiserver_request_total:rate5m{cluster="$cluster", verb="write", code=~"5.."}) / sum by (resource) (code_resource:apiserver_request_total:rate5m{cluster="$cluster", verb="write"})', '{{resource}}')]),
      local writeDuration = timeSeriesBase('Write SLI - Duration', 's') + timeSeriesPanel.queryOptions.withTargets([promTarget('cluster_quantile:apiserver_request_sli_duration_seconds:histogram_quantile{cluster="$cluster", verb="write"}', '{{resource}}')]),
      local health = statBase('Health', healthTemplate.panel.expr, 'percent', $.grafanaThresholds(healthTemplate.panel.thresholds)),

      local grpcRate = timeSeriesBase('GRPC Rate', 'reqps') + timeSeriesPanel.queryOptions.withTargets([
        promTarget('sum(rate(apiserver_request_total{cluster="$cluster", %(apiServer)s, instance=~"$instance", code=~"2.."}[5m]))' % sel, '2xx'),
        promTarget('sum(rate(apiserver_request_total{cluster="$cluster", %(apiServer)s, instance=~"$instance", code=~"3.."}[5m]))' % sel, '3xx'),
        promTarget('sum(rate(apiserver_request_total{cluster="$cluster", %(apiServer)s, instance=~"$instance", code=~"4.."}[5m]))' % sel, '4xx'),
        promTarget('sum(rate(apiserver_request_total{cluster="$cluster", %(apiServer)s, instance=~"$instance", code=~"5.."}[5m]))' % sel, '5xx'),
      ]),

      local requestDuration = timeSeriesBase('Request duration 99th quantile') + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.99, sum(rate(apiserver_request_duration_seconds_bucket{cluster="$cluster", %(apiServer)s, instance=~"$instance", verb!="WATCH"}[5m])) by (verb, le))' % sel, '{{verb}}')]),
      local workQueueAddRate = timeSeriesBase('Work Queue Add Rate', 'ops', min=0, showLegend=false) + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(workqueue_adds_total{cluster="$cluster", %(apiServer)s, instance=~"$instance"}[5m])) by (instance, name)' % sel, '{{instance}} {{name}}')]),
      local workQueueDepth = timeSeriesBase('Work Queue Depth', min=0, showLegend=false) + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(workqueue_depth{cluster="$cluster", %(apiServer)s, instance=~"$instance"}[5m])) by (instance, name)' % sel, '{{instance}} {{name}}')]),
      local workQueueLatency = timeSeriesBase('Work Queue Latency', 's', legendTable=true) + timeSeriesPanel.queryOptions.withTargets([promTarget('histogram_quantile(0.99, sum(rate(workqueue_queue_duration_seconds_bucket{cluster="$cluster", %(apiServer)s, instance=~"$instance"}[5m])) by (instance, name, le))' % sel, '{{instance}} {{name}}')]),
      local memory = timeSeriesBase('Memory', 'bytes') + timeSeriesPanel.queryOptions.withTargets([promTarget('process_resident_memory_bytes{cluster="$cluster", %(apiServer)s, instance=~"$instance"}' % sel, '{{instance}}')]),
      local cpu = timeSeriesBase('CPU Usage', min=0) + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(process_cpu_seconds_total{cluster="$cluster", %(apiServer)s, instance=~"$instance"}[5m])' % sel, '{{instance}}')]),
      local goroutines = timeSeriesBase('Goroutines') + timeSeriesPanel.queryOptions.withTargets([promTarget('go_goroutines{cluster="$cluster", %(apiServer)s, instance=~"$instance"}' % sel, '{{instance}}')]),

      dashboard:
        dashboard.new(dashboardName)
        + dashboard.withUid(dashboardUid)
        + dashboard.withTags($._config.grafanaDashboards.tags.k8sSystem)
        + dashboard.withEditable($._config.grafanaDashboards.editable)
        + dashboard.withRefresh($._config.grafanaDashboards.refresh)
        + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
        + $._config.grafanaDashboards.tooltip
        + dashboard.withTimezone('browser')
        + dashboard.withVariables([
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.clusterTemplate('label_values(apiserver_request_total, cluster)'),
          $.grafanaTemplates.instanceTemplate('label_values(apiserver_request_total{cluster="$cluster", %(apiServer)s}, instance)' % sel),
        ])
        + dashboard.withPanels([
          availability1d { gridPos: { x: 0, y: 0, w: 8, h: 7 } },
          errorBudget { gridPos: { x: 8, y: 0, w: 16, h: 7 } },
          readAvailability { gridPos: { x: 0, y: 7, w: 6, h: 7 } },
          readRequests { gridPos: { x: 6, y: 7, w: 6, h: 7 } },
          readErrors { gridPos: { x: 12, y: 7, w: 6, h: 7 } },
          readDuration { gridPos: { x: 18, y: 7, w: 6, h: 7 } },
          writeAvailability { gridPos: { x: 0, y: 14, w: 6, h: 7 } },
          writeRequests { gridPos: { x: 6, y: 14, w: 6, h: 7 } },
          writeErrors { gridPos: { x: 12, y: 14, w: 6, h: 7 } },
          writeDuration { gridPos: { x: 18, y: 14, w: 6, h: 7 } },
          health { gridPos: { x: 0, y: 21, w: 4, h: 7 } },
          grpcRate { gridPos: { x: 4, y: 21, w: 10, h: 7 } },
          requestDuration { gridPos: { x: 14, y: 21, w: 10, h: 7 } },
          workQueueAddRate { gridPos: { x: 0, y: 28, w: 12, h: 7 } },
          workQueueDepth { gridPos: { x: 12, y: 28, w: 12, h: 7 } },
          workQueueLatency { gridPos: { x: 0, y: 35, w: 24, h: 7 } },
          memory { gridPos: { x: 0, y: 42, w: 8, h: 7 } },
          cpu { gridPos: { x: 8, y: 42, w: 8, h: 7 } },
          goroutines { gridPos: { x: 16, y: 42, w: 8, h: 7 } },
        ]),
    };
    $.createControlPlaneDashboard(
      jsonName='api-server',
      dashboardFunction=apiServerDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.apiServer,
      dashboardName='Api Server',
      templateGroup=$._config.templates.L1.k8s,
      templateName='apiServerHealth',
    ),
}
