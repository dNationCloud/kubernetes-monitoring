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

/* K8s harbor dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local gaugePanel = grafana.panel.gauge;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    harbor:
      local color = $._config.grafanaDashboards.color;

      local promTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local timeSeriesBase(title, expr, legendFormat=null, unit=null, desc=null) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + (if desc != null then timeSeriesPanel.panelOptions.withDescription(desc) else {})
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc')
        + timeSeriesPanel.queryOptions.withTargets([promTarget(expr, legendFormat)]);

      local harborHealth =
        gaugePanel.new('Harbor Health')
        + gaugePanel.queryOptions.withDatasource('prometheus', '$datasource')
        + gaugePanel.standardOptions.withUnit('percentunit')
        + gaugePanel.standardOptions.withMin(0)
        + gaugePanel.standardOptions.withMax(1)
        + gaugePanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + gaugePanel.options.withShowThresholdMarkers(false)
        + gaugePanel.standardOptions.thresholds.withMode('absolute')
        + gaugePanel.standardOptions.thresholds.withSteps([{ color: color.red, value: null }, { color: color.green, value: 1 }])
        + gaugePanel.queryOptions.withTargets([promTarget('harbor_health{cluster="$cluster", job=~"$job"}')]);

      local componentUp = timeSeriesBase('Component Up Status', 'harbor_up{cluster="$cluster", job=~"$job"}', '{{component}}');
      local systemInfo = timeSeriesBase('System Info', 'harbor_system_info{cluster="$cluster", job=~"$job"}');
      local artifactPulled = timeSeriesBase('Artifact Pulled', 'harbor_artifact_pulled{cluster="$cluster", job=~"$job"}', '{{project_name}}');
      local projectTotal = timeSeriesBase('Project Total', 'harbor_project_total{cluster="$cluster", job=~"$job"}', 'public="{{public}}"');
      local projectMembers = timeSeriesBase('Project Members', 'harbor_project_member_total{cluster="$cluster", job=~"$job"}', '{{project_name}}');
      local quotaUsage = timeSeriesBase('Quota Usage', 'harbor_project_quota_usage_byte{cluster="$cluster", job=~"$job"}', '{{project_name}}', 'bytes');
      local projectRepoTotal = timeSeriesBase('Project Repo Total', 'harbor_project_repo_total{cluster="$cluster", job=~"$job"}', '{{project_name}}');
      local goInfo = timeSeriesBase('Go Info', 'go_info{cluster="$cluster", job=~"$job"}');
      local processCpuTime = timeSeriesBase('Process CPU Time', 'rate(process_cpu_seconds_total{cluster="$cluster", job=~"$job"}[5m])');
      local goThreads = timeSeriesBase('Go Threads', 'go_threads{cluster="$cluster", job=~"$job"}');
      local goroutines = timeSeriesBase('Goroutines', 'go_goroutines{cluster="$cluster", job=~"$job"}');
      local processOpenedFd = timeSeriesBase('Process Opened Fd', 'process_open_fds{cluster="$cluster", job=~"$job"}');
      local goHeapObjects = timeSeriesBase('Go Heap Objects', 'go_memstats_heap_objects{cluster="$cluster", job=~"$job"}');
      local goAllocatedMemory = timeSeriesBase('Go Allocated Memory', 'go_memstats_alloc_bytes{cluster="$cluster", job=~"$job"}', unit='bytes');
      local goNextGcBytes = timeSeriesBase('Go Next Gc Bytes', 'go_memstats_next_gc_bytes{cluster="$cluster", job=~"$job"}', unit='bytes');
      local goGcTime_025 = timeSeriesBase('Go Gc Time 0.25', 'go_gc_duration_seconds{quantile="0.25", cluster="$cluster", job=~"$job"}', unit='s');
      local goGcTime_050 = timeSeriesBase('Go Gc Time 0.5', 'go_gc_duration_seconds{quantile="0.5", cluster="$cluster", job=~"$job"}', unit='s');
      local goGcTime_075 = timeSeriesBase('Go Gc Time 0.75', 'go_gc_duration_seconds{quantile="0.75", cluster="$cluster", job=~"$job"}', unit='s');
      local apiRequestTime_050 = timeSeriesBase('API Request Time 0.5', 'harbor_core_http_request_duration_seconds{quantile="0.5", cluster="$cluster", job=~"$job"}', '{{instance}}-{{operation}}', 's');
      local apiRequestTime_090 = timeSeriesBase('API Request Time 0.9', 'harbor_core_http_request_duration_seconds{quantile="0.9", cluster="$cluster", job=~"$job"}', '{{instance}}-{{operation}}', 's');
      local apiRequestTime_099 = timeSeriesBase('API Request Time 0.99', 'harbor_core_http_request_duration_seconds{quantile="0.99", cluster="$cluster", job=~"$job"}', '{{instance}}-{{operation}}', 's');
      local harborCoreRequestTotal = timeSeriesBase('Harbor Core Request Total', 'rate(harbor_core_http_request_total{cluster="$cluster", job=~"$job"}[5m])', '{{instance}}-{{operation}}');
      local harborCoreInflightRequest = timeSeriesBase('Harbor Core Inflight Request', 'harbor_core_http_inflight_requests{cluster="$cluster", job=~"$job"}');
      local jobServiceInfo = timeSeriesBase('Job Service Info', 'harbor_jobservice_info{cluster="$cluster", job=~"$job"}');
      local taskQueuePendingSize = timeSeriesBase('Task Queue Pending Size', 'harbor_task_queue_size{cluster="$cluster", job=~"$job"}', '{{type}}');
      local taskLatency = timeSeriesBase('Task Latency', 'harbor_task_queue_latency{cluster="$cluster", job=~"$job"}', '{{type}}', 's', 'Time period from last process of task queue');
      local taskConcurrency = timeSeriesBase('Task Concurrency', 'harbor_task_concurrency{cluster="$cluster", job=~"$job"}', '{{type}}-{{pool}}');
      local tasksPerMinute = timeSeriesBase('Tasks Per Minute', 'rate(harbor_jobservice_task_total{cluster="$cluster", job=~"$job"}[1m])', '{{type}} {{status}}');
      local numberRunningScheduledJob = timeSeriesBase('Number Of Running Scheduled Job', 'harbor_task_scheduled_total{cluster="$cluster", job=~"$job"}');
      local taskProcessTime_050 = timeSeriesBase('Task Process Time 0.5', 'harbor_jobservice_task_process_time_seconds{quantile="0.5", cluster="$cluster", job=~"$job"}', '{{type}} {{status}}', 's');
      local taskProcessTime_090 = timeSeriesBase('Task Process Time 0.9', 'harbor_jobservice_task_process_time_seconds{quantile="0.9", cluster="$cluster", job=~"$job"}', '{{type}} {{status}}', 's');
      local taskProcessTime_099 = timeSeriesBase('Task Process Time 0.99', 'harbor_jobservice_task_process_time_seconds{quantile="0.99", cluster="$cluster", job=~"$job"}', '{{type}} {{status}}', 's');
      local registryRequestInflight = timeSeriesBase('Registry Request Inflight', 'registry_http_in_flight_requests{cluster="$cluster", job=~"$job"}', '{{handler}}');
      local registryRequestRate = timeSeriesBase('Registry Request Rate', 'rate(registry_http_requests_total{cluster="$cluster", job=~"$job"}[5m])');
      local registryStorageCache = timeSeriesBase('Registry Storage Cache', 'rate(registry_storage_cache_total{cluster="$cluster", job=~"$job"}[5m])', '{{type}}');
      local registryRequestTime_050 = timeSeriesBase('Registry Request Time 0.5', 'histogram_quantile(0.5, rate(registry_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job"}[10m]))', unit='s');
      local registryRequestTime_090 = timeSeriesBase('Registry Request Time 0.9', 'histogram_quantile(0.9, rate(registry_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job"}[10m]))', unit='s');
      local registryRequestTime_099 = timeSeriesBase('Registry Request Time 0.99', 'histogram_quantile(0.99, rate(registry_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job"}[10m]))', unit='s');
      local registryRequestSize_090 = timeSeriesBase('Registry Request Size 0.9', 'histogram_quantile(0.9, rate(registry_http_request_size_bytes_bucket{cluster="$cluster", job=~"$job"}[10m]))', unit='bytes');
      local registryResponseSize_090 = timeSeriesBase('Registry Response Size 0.9', 'histogram_quantile(0.9, rate(registry_http_response_size_bytes_bucket{cluster="$cluster", job=~"$job"}[10m]))', unit='bytes');
      local registryStorageActionTime_090 = timeSeriesBase('Registry Storage Action Time 0.9', 'histogram_quantile(0.9, rate(registry_storage_action_seconds_bucket{cluster="$cluster", job=~"$job"}[10m]))', unit='s');

      local panels = [
        row.new('Info') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        harborHealth { gridPos: { x: 0, y: 1, w: 4, h: 6 } },
        componentUp { gridPos: { x: 4, y: 1, w: 6, h: 6 } },
        systemInfo { gridPos: { x: 10, y: 1, w: 8, h: 6 } },
        artifactPulled { gridPos: { x: 18, y: 1, w: 6, h: 6 } },
        projectTotal { gridPos: { x: 0, y: 7, w: 6, h: 7 } },
        projectMembers { gridPos: { x: 6, y: 7, w: 6, h: 7 } },
        quotaUsage { gridPos: { x: 12, y: 7, w: 6, h: 7 } },
        projectRepoTotal { gridPos: { x: 18, y: 7, w: 6, h: 7 } },
        row.new('General Metrics') + { gridPos: { x: 0, y: 14, w: 24, h: 1 } },
        goInfo { gridPos: { x: 0, y: 15, w: 6, h: 8 } },
        processCpuTime { gridPos: { x: 6, y: 15, w: 6, h: 8 } },
        goThreads { gridPos: { x: 12, y: 15, w: 6, h: 8 } },
        goroutines { gridPos: { x: 18, y: 15, w: 6, h: 8 } },
        processOpenedFd { gridPos: { x: 0, y: 23, w: 6, h: 8 } },
        goHeapObjects { gridPos: { x: 6, y: 23, w: 6, h: 8 } },
        goAllocatedMemory { gridPos: { x: 12, y: 23, w: 6, h: 8 } },
        goNextGcBytes { gridPos: { x: 18, y: 23, w: 6, h: 8 } },
        goGcTime_025 { gridPos: { x: 0, y: 31, w: 8, h: 8 } },
        goGcTime_050 { gridPos: { x: 8, y: 31, w: 8, h: 8 } },
        goGcTime_075 { gridPos: { x: 16, y: 31, w: 8, h: 8 } },
        row.new('Core Metrics') + { gridPos: { x: 0, y: 39, w: 24, h: 1 } },
        apiRequestTime_050 { gridPos: { x: 0, y: 40, w: 8, h: 7 } },
        apiRequestTime_090 { gridPos: { x: 8, y: 40, w: 8, h: 7 } },
        apiRequestTime_099 { gridPos: { x: 16, y: 40, w: 8, h: 7 } },
        harborCoreRequestTotal { gridPos: { x: 0, y: 47, w: 8, h: 7 } },
        harborCoreInflightRequest { gridPos: { x: 8, y: 47, w: 8, h: 7 } },
        row.new('JobService Metrics') + { gridPos: { x: 0, y: 54, w: 24, h: 1 } },
        jobServiceInfo { gridPos: { x: 0, y: 55, w: 8, h: 7 } },
        taskQueuePendingSize { gridPos: { x: 8, y: 55, w: 8, h: 7 } },
        numberRunningScheduledJob { gridPos: { x: 16, y: 55, w: 8, h: 7 } },
        taskLatency { gridPos: { x: 0, y: 62, w: 8, h: 8 } },
        taskConcurrency { gridPos: { x: 8, y: 62, w: 8, h: 8 } },
        tasksPerMinute { gridPos: { x: 16, y: 62, w: 8, h: 8 } },
        taskProcessTime_050 { gridPos: { x: 0, y: 70, w: 8, h: 6 } },
        taskProcessTime_090 { gridPos: { x: 8, y: 70, w: 8, h: 6 } },
        taskProcessTime_099 { gridPos: { x: 16, y: 70, w: 8, h: 6 } },
        row.new('Registry Metrics') + { gridPos: { x: 0, y: 76, w: 24, h: 1 } },
        registryRequestInflight { gridPos: { x: 0, y: 77, w: 8, h: 8 } },
        registryRequestRate { gridPos: { x: 8, y: 77, w: 8, h: 8 } },
        registryStorageCache { gridPos: { x: 16, y: 77, w: 8, h: 8 } },
        registryRequestTime_050 { gridPos: { x: 0, y: 85, w: 8, h: 8 } },
        registryRequestTime_090 { gridPos: { x: 8, y: 85, w: 8, h: 8 } },
        registryRequestTime_099 { gridPos: { x: 16, y: 85, w: 8, h: 8 } },
        registryRequestSize_090 { gridPos: { x: 0, y: 93, w: 8, h: 8 } },
        registryResponseSize_090 { gridPos: { x: 8, y: 93, w: 8, h: 8 } },
        registryStorageActionTime_090 { gridPos: { x: 16, y: 93, w: 8, h: 8 } },
      ];

      dashboard.new('Harbor')
      + dashboard.withUid($._config.grafanaDashboards.ids.harbor)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.jobTemplate('label_values(harbor_health, job)'),
        $.grafanaTemplates.clusterTemplate('label_values(harbor_health{job=~"$job"}, cluster)'),
      ])
      + dashboard.withPanels(panels),
  },
}
