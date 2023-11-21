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
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local gaugePanel = grafana.gaugePanel;
local graphPanel = grafana.graphPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    harbor:
      local harborHealth =
        gaugePanel.new(
          title='Harbor Health',
          datasource='$datasource',
          reducerFunction='lastNotNull',
          unit='percentunit',
          showThresholdMarkers=false,
          min=0,
          max=1,
        )
        .addTarget(prometheus.target('harbor_health{cluster="$cluster", job=~"$job"}'))
        .addThresholds(
          [
            { color: $._config.grafanaDashboards.color.red, value: null },
            { color: $._config.grafanaDashboards.color.green, value: 1 },
          ]
        );

      local componentUp =
        graphPanel.new(
          title='Component Up Status',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('harbor_up{cluster="$cluster", job=~"$job"}', legendFormat='{{component}}'));

      local systemInfo =
        graphPanel.new(
          title='System Info',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('harbor_system_info{cluster="$cluster", job=~"$job"}'));

      local artifactPulled =
        graphPanel.new(
          title='Artifact Pulled',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('harbor_artifact_pulled{cluster="$cluster", job=~"$job"}', legendFormat='{{project_name}}'));

      local projectTotal =
        graphPanel.new(
          title='Project Total',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('harbor_project_total{cluster="$cluster", job=~"$job"}', legendFormat='public="{{public}}"'));

      local projectMembers =
        graphPanel.new(
          title='Project Members',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('harbor_project_member_total{cluster="$cluster", job=~"$job"}', legendFormat='{{project_name}}'));

      local quotaUsage =
        graphPanel.new(
          title='Quota Usage',
          datasource='$datasource',
          format='bytes',
        )
        .addTarget(prometheus.target('harbor_project_quota_usage_byte{cluster="$cluster", job=~"$job"}', legendFormat='{{project_name}}'));

      local projectRepoTotal =
        graphPanel.new(
          title='Project Repo Total',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('harbor_project_repo_total{cluster="$cluster", job=~"$job"}', legendFormat='{{project_name}}'));

      local goInfo =
        graphPanel.new(
          title='Go Info',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('go_info{cluster="$cluster", job=~"$job"}'));

      local processCpuTime =
        graphPanel.new(
          title='Process CPU Time',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('rate(process_cpu_seconds_total{cluster="$cluster", job=~"$job"}[5m])'));

      local goThreads =
        graphPanel.new(
          title='Go Threads',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('go_threads{cluster="$cluster", job=~"$job"}'));

      local goroutines =
        graphPanel.new(
          title='Goroutines',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('go_goroutines{cluster="$cluster", job=~"$job"}'));

      local processOpenedFd =
        graphPanel.new(
          title='Process Opened Fd',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('process_open_fds{cluster="$cluster", job=~"$job"}'));

      local goHeapObjects =
        graphPanel.new(
          title='Go Heap Objects',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('go_memstats_heap_objects{cluster="$cluster", job=~"$job"}'));

      local goAllocatedMemory =
        graphPanel.new(
          title='Go Allocated Memory',
          datasource='$datasource',
          format='bytes',
        )
        .addTarget(prometheus.target('go_memstats_alloc_bytes{cluster="$cluster", job=~"$job"}'));

      local goNextGcBytes =
        graphPanel.new(
          title='Go Next Gc Bytes',
          datasource='$datasource',
          format='bytes',
        )
        .addTarget(prometheus.target('go_memstats_next_gc_bytes{cluster="$cluster", job=~"$job"}'));

      local goGcTime_025 =
        graphPanel.new(
          title='Go Gc Time 0.25',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('go_gc_duration_seconds{quantile="0.25", cluster="$cluster", job=~"$job"}'));

      local goGcTime_050 =
        graphPanel.new(
          title='Go Gc Time 0.5',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('go_gc_duration_seconds{quantile="0.5", cluster="$cluster", job=~"$job"}'));

      local goGcTime_075 =
        graphPanel.new(
          title='Go Gc Time 0.75',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('go_gc_duration_seconds{quantile="0.75", cluster="$cluster", job=~"$job"}'));

      local apiRequestTime_050 =
        graphPanel.new(
          title='API Request Time 0.5',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('harbor_core_http_request_duration_seconds{quantile="0.5", cluster="$cluster", job=~"$job"}', legendFormat='{{instance}}-{{operation}}'));

      local apiRequestTime_090 =
        graphPanel.new(
          title='API Request Time 0.9',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('harbor_core_http_request_duration_seconds{quantile="0.9", cluster="$cluster", job=~"$job"}', legendFormat='{{instance}}-{{operation}}'));

      local apiRequestTime_099 =
        graphPanel.new(
          title='API Request Time 0.99',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('harbor_core_http_request_duration_seconds{quantile="0.99", cluster="$cluster", job=~"$job"}', legendFormat='{{instance}}-{{operation}}'));

      local harborCoreRequestTotal =
        graphPanel.new(
          title='Harbor Core Request Total',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('rate(harbor_core_http_request_total{cluster="$cluster", job=~"$job"}[5m])', legendFormat='{{instance}}-{{operation}}'));

      local harborCoreInflightRequest =
        graphPanel.new(
          title='Harbor Core Inflight Request',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('harbor_core_http_inflight_requests{cluster="$cluster", job=~"$job"}'));

      local jobServiceInfo =
        graphPanel.new(
          title='Job Service Info',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('harbor_jobservice_info{cluster="$cluster", job=~"$job"}'));

      local taskQueuePendingSize =
        graphPanel.new(
          title='Task Queue Pending Size',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('harbor_task_queue_size{cluster="$cluster", job=~"$job"}', legendFormat='{{type}}'));

      local taskLatency =
        graphPanel.new(
          title='Task Latency',
          description='Time period from last process of task queue',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('harbor_task_queue_latency{cluster="$cluster", job=~"$job"}', legendFormat='{{type}}'));

      local taskConcurrency =
        graphPanel.new(
          title='Task Concurrency',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('harbor_task_concurrency{cluster="$cluster", job=~"$job"}', legendFormat='{{type}}-{{pool}}'));

      local tasksPerMinute =
        graphPanel.new(
          title='Tasks Per Minute',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('rate(harbor_jobservice_task_total{cluster="$cluster", job=~"$job"}[1m])', legendFormat='{{type}} {{status}}'));

      local numberRunningScheduledJob =
        graphPanel.new(
          title='Number Of Running Scheduled Job',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('harbor_task_scheduled_total{cluster="$cluster", job=~"$job"}'));

      local taskProcessTime_050 =
        graphPanel.new(
          title='Task Process Time 0.5',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('harbor_jobservice_task_process_time_seconds{quantile="0.5", cluster="$cluster", job=~"$job"}', legendFormat='{{type}} {{status}}'));

      local taskProcessTime_090 =
        graphPanel.new(
          title='Task Process Time 0.9',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('harbor_jobservice_task_process_time_seconds{quantile="0.9", cluster="$cluster", job=~"$job"}', legendFormat='{{type}} {{status}}'));

      local taskProcessTime_099 =
        graphPanel.new(
          title='Task Process Time 0.99',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('harbor_jobservice_task_process_time_seconds{quantile="0.99", cluster="$cluster", job=~"$job"}', legendFormat='{{type}} {{status}}'));

      local registryRequestInflight =
        graphPanel.new(
          title='Registry Request Inflight',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('registry_http_in_flight_requests{cluster="$cluster", job=~"$job"}', legendFormat='{{handler}}'));

      local registryRequestRate =
        graphPanel.new(
          title='Registry Request Rate',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('rate(registry_http_requests_total{cluster="$cluster", job=~"$job"}[5m])'));

      local registryStorageCache =
        graphPanel.new(
          title='Registry Storage Cache',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('rate(registry_storage_cache_total{cluster="$cluster", job=~"$job"}[5m])', legendFormat='{{type}}'));

      local registryRequestTime_050 =
        graphPanel.new(
          title='Registry Request Time 0.5',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('histogram_quantile(0.5, rate(registry_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job"}[10m]))'));

      local registryRequestTime_090 =
        graphPanel.new(
          title='Registry Request Time 0.9',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('histogram_quantile(0.9, rate(registry_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job"}[10m]))'));

      local registryRequestTime_099 =
        graphPanel.new(
          title='Registry Request Time 0.99',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, rate(registry_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job"}[10m]))'));

      local registryRequestSize_090 =
        graphPanel.new(
          title='Registry Request Size 0.9',
          datasource='$datasource',
          format='bytes',
        )
        .addTarget(prometheus.target('histogram_quantile(0.9, rate(registry_http_request_size_bytes_bucket{cluster="$cluster", job=~"$job"}[10m]))'));

      local registryResponseSize_090 =
        graphPanel.new(
          title='Registry Response Size 0.9',
          datasource='$datasource',
          format='bytes',
        )
        .addTarget(prometheus.target('histogram_quantile(0.9, rate(registry_http_response_size_bytes_bucket{cluster="$cluster", job=~"$job"}[10m]))'));

      local registryStorageActionTime_090 =
        graphPanel.new(
          title='Registry Storage Action Time 0.9',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('histogram_quantile(0.9, rate(registry_storage_action_seconds_bucket{cluster="$cluster", job=~"$job"}[10m]))'));

      local templates =
        [
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.jobTemplate('label_values(harbor_health, job)'),
          $.grafanaTemplates.clusterTemplate('label_values(harbor_health{job=~"$job"}, cluster)'),
        ];

      local panels = [
        row.new('Info') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        harborHealth { gridPos: { x: 0, y: 1, w: 4, h: 6 } },
        componentUp { tooltip+: { sort: 2 }, gridPos: { x: 4, y: 1, w: 6, h: 6 } },
        systemInfo { tooltip+: { sort: 2 }, gridPos: { x: 10, y: 1, w: 8, h: 6 } },
        artifactPulled { tooltip+: { sort: 2 }, gridPos: { x: 18, y: 1, w: 6, h: 6 } },
        projectTotal { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 7, w: 6, h: 7 } },
        projectMembers { tooltip+: { sort: 2 }, gridPos: { x: 6, y: 7, w: 6, h: 7 } },
        quotaUsage { tooltip+: { sort: 2 }, gridPos: { x: 12, y: 7, w: 6, h: 7 } },
        projectRepoTotal { tooltip+: { sort: 2 }, gridPos: { x: 18, y: 7, w: 6, h: 7 } },
        row.new('General Metrics', collapse=true) { gridPos: { x: 0, y: 14, w: 24, h: 1 } }
        .addPanel(goInfo { tooltip+: { sort: 2 } }, { x: 0, y: 2, w: 6, h: 8 })
        .addPanel(processCpuTime { tooltip+: { sort: 2 } }, { x: 6, y: 2, w: 6, h: 8 })
        .addPanel(goThreads { tooltip+: { sort: 2 } }, { x: 12, y: 2, w: 6, h: 8 })
        .addPanel(goroutines { tooltip+: { sort: 2 } }, { x: 18, y: 2, w: 6, h: 8 })
        .addPanel(processOpenedFd { tooltip+: { sort: 2 } }, { x: 0, y: 10, w: 6, h: 8 })
        .addPanel(goHeapObjects { tooltip+: { sort: 2 } }, { x: 6, y: 10, w: 6, h: 8 })
        .addPanel(goAllocatedMemory { tooltip+: { sort: 2 } }, { x: 12, y: 10, w: 6, h: 8 })
        .addPanel(goNextGcBytes { tooltip+: { sort: 2 } }, { x: 18, y: 10, w: 6, h: 8 })
        .addPanel(goGcTime_025 { tooltip+: { sort: 2 } }, { x: 0, y: 18, w: 8, h: 8 })
        .addPanel(goGcTime_050 { tooltip+: { sort: 2 } }, { x: 8, y: 18, w: 8, h: 8 })
        .addPanel(goGcTime_075 { tooltip+: { sort: 2 } }, { x: 16, y: 18, w: 8, h: 8 }),
        row.new('Core Metrics', collapse=true) { gridPos: { x: 0, y: 15, w: 24, h: 1 } }
        .addPanel(apiRequestTime_050 { tooltip+: { sort: 2 } }, { x: 0, y: 3, w: 8, h: 7 })
        .addPanel(apiRequestTime_090 { tooltip+: { sort: 2 } }, { x: 8, y: 3, w: 8, h: 7 })
        .addPanel(apiRequestTime_099 { tooltip+: { sort: 2 } }, { x: 16, y: 3, w: 8, h: 7 })
        .addPanel(harborCoreRequestTotal { tooltip+: { sort: 2 } }, { x: 0, y: 10, w: 8, h: 7 })
        .addPanel(harborCoreInflightRequest { tooltip+: { sort: 2 } }, { x: 8, y: 10, w: 8, h: 7 }),
        row.new('JobService Metrics', collapse=true) { gridPos: { x: 0, y: 16, w: 24, h: 1 } }
        .addPanel(jobServiceInfo { tooltip+: { sort: 2 } }, { x: 0, y: 4, w: 8, h: 7 })
        .addPanel(taskQueuePendingSize { tooltip+: { sort: 2 } }, { x: 8, y: 4, w: 8, h: 7 })
        .addPanel(numberRunningScheduledJob { tooltip+: { sort: 2 } }, { x: 16, y: 4, w: 8, h: 7 })
        .addPanel(taskLatency { tooltip+: { sort: 2 } }, { x: 0, y: 11, w: 8, h: 8 })
        .addPanel(taskConcurrency { tooltip+: { sort: 2 } }, { x: 8, y: 11, w: 8, h: 8 })
        .addPanel(tasksPerMinute { tooltip+: { sort: 2 } }, { x: 16, y: 11, w: 8, h: 8 })
        .addPanel(taskProcessTime_050 { tooltip+: { sort: 2 } }, { x: 0, y: 19, w: 8, h: 6 })
        .addPanel(taskProcessTime_090 { tooltip+: { sort: 2 } }, { x: 8, y: 19, w: 8, h: 6 })
        .addPanel(taskProcessTime_099 { tooltip+: { sort: 2 } }, { x: 16, y: 19, w: 8, h: 6 }),
        row.new('Registry Metrics', collapse=true) { gridPos: { x: 0, y: 17, w: 24, h: 1 } }
        .addPanel(registryRequestInflight { tooltip+: { sort: 2 } }, { x: 0, y: 5, w: 8, h: 8 })
        .addPanel(registryRequestRate { tooltip+: { sort: 2 } }, { x: 8, y: 5, w: 8, h: 8 })
        .addPanel(registryStorageCache { tooltip+: { sort: 2 } }, { x: 16, y: 5, w: 8, h: 8 })
        .addPanel(registryRequestTime_050 { tooltip+: { sort: 2 } }, { x: 0, y: 13, w: 8, h: 8 })
        .addPanel(registryRequestTime_090 { tooltip+: { sort: 2 } }, { x: 8, y: 13, w: 8, h: 8 })
        .addPanel(registryRequestTime_099 { tooltip+: { sort: 2 } }, { x: 16, y: 13, w: 8, h: 8 })
        .addPanel(registryRequestSize_090 { tooltip+: { sort: 2 } }, { x: 0, y: 21, w: 8, h: 8 })
        .addPanel(registryResponseSize_090 { tooltip+: { sort: 2 } }, { x: 8, y: 21, w: 8, h: 8 })
        .addPanel(registryStorageActionTime_090 { tooltip+: { sort: 2 } }, { x: 16, y: 21, w: 8, h: 8 }),
      ];

      dashboard.new(
        'Harbor',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.harbor,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
