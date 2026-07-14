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

/* K8s java actuator dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local logPanel = grafana.panel.logs;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;
local loki = grafana.query.loki;
local fieldOverride = grafana.panel.timeSeries.fieldOverride;

{
  grafanaDashboards+:: {
    'java-actuator':
      local color = $._config.grafanaDashboards.color;

      local colorOverride(alias, col) = fieldOverride.byRegexp.new(alias)
                                          + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: col });

      local promTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local lokiTarget(expr, legendFormat=null) =
        loki.withExpr(expr) + (if legendFormat != null then loki.withLegendFormat(legendFormat) else {});

      local timeSeriesBase(title, unit=null, min=null, stack=false, spanNullsFalse=false, calcs=[], overrides=[], log10=false, repeat=null, maxPerRow=null) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + (if min != null then timeSeriesPanel.standardOptions.withMin(min) else {})
        + (if stack then timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' }) else {})
        + (if spanNullsFalse then timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false) else {})
        + (if log10 then timeSeriesPanel.fieldConfig.defaults.custom.scaleDistribution.withType('log') + timeSeriesPanel.fieldConfig.defaults.custom.scaleDistribution.withLog(10) else {})
        + (if std.length(calcs) > 0 then timeSeriesPanel.options.legend.withDisplayMode('list') + timeSeriesPanel.options.legend.withCalcs(calcs) else {})
        + (if std.length(overrides) > 0 then timeSeriesPanel.standardOptions.withOverrides(overrides) else {})
        + (if repeat != null then timeSeriesPanel.panelOptions.withRepeat(repeat) + timeSeriesPanel.panelOptions.withRepeatDirection('h') else {})
        + (if maxPerRow != null then timeSeriesPanel.panelOptions.withMaxPerRow(maxPerRow) else {})
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc');

      local podReqLimitOverrides = [
        fieldOverride.byRegexp.new('/PodRequests/')
          + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: color.red })
          + fieldOverride.byRegexp.withProperty('custom.lineStyle', { fill: 'dash' })
          + fieldOverride.byRegexp.withProperty('custom.fillOpacity', 0)
          + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'none' })
          + fieldOverride.byRegexp.withProperty('custom.hideFrom', { tooltip: true, legend: false, viz: false }),
        fieldOverride.byRegexp.new('/PodLimits/')
          + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: color.orange })
          + fieldOverride.byRegexp.withProperty('custom.lineStyle', { fill: 'dash' })
          + fieldOverride.byRegexp.withProperty('custom.fillOpacity', 0)
          + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'none' })
          + fieldOverride.byRegexp.withProperty('custom.hideFrom', { tooltip: true, legend: false, viz: false }),
      ];

      local rxTxOverrides = [
        fieldOverride.byRegexp.new('/Rx_/')
          + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'B' })
          + fieldOverride.byRegexp.withProperty('custom.transform', 'negative-Y'),
        fieldOverride.byRegexp.new('/Tx_/')
          + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'A' }),
      ];

      local cpu =
        timeSeriesBase('CPU Usage', 'core', min=0, stack=true, spanNullsFalse=true, overrides=podReqLimitOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", container=~"$container"}) by ($view)', '{{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_requests{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodRequests - {{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_limits{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodLimits - {{$view}}'),
        ]);

      local memory =
        timeSeriesBase('Memory Usage', 'bytes', min=0, stack=true, spanNullsFalse=true, overrides=podReqLimitOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(container_memory_working_set_bytes{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", id!="", container!="POD", container=~"$container"}) by ($view)', '{{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_requests{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodRequests - {{$view}}'),
          promTarget('sum(\nkube_pod_container_resource_limits{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', 'PodLimits - {{$view}}'),
        ]);

      local bandwidth =
        timeSeriesBase('Transmit/Receive Bandwidth', 'Bps', stack=true, spanNullsFalse=true, overrides=rxTxOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(container_network_transmit_bytes_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Tx_{{pod}}'),
          promTarget('sum(irate(container_network_receive_bytes_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Rx_{{pod}}'),
        ]);

      local drops =
        timeSeriesBase('Transmit/Receive Drops', 'pps', stack=true, spanNullsFalse=true, overrides=rxTxOverrides)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(irate(container_network_transmit_packets_dropped_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Tx_{{pod}}'),
          promTarget('sum(irate(container_network_receive_packets_dropped_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', 'Rx_{{pod}}'),
        ]);

      local count =
        timeSeriesBase('Count (avg for 10s intervals)',
                       'short',
                       min=0,
                       stack=true,
                       spanNullsFalse=true,
                       calcs=['lastNotNull'],
                       overrides=[fieldOverride.byRegexp.new('Value #A')
                                    + fieldOverride.byRegexp.withProperty('custom.hideFrom', { legend: true, tooltip: false, viz: true })])
        + timeSeriesPanel.options.legend.withDisplayMode('table') + timeSeriesPanel.options.legend.withPlacement('right')
        + timeSeriesPanel.options.legend.withSortBy('Last *') + timeSeriesPanel.options.legend.withSortDesc(true)
        + timeSeriesPanel.queryOptions.withTargets([
          lokiTarget('sum(count_over_time({cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"[10s])) by ($view)', '{{$view}}'),
        ])
        + timeSeriesPanel.queryOptions.withDatasource('loki', '$datasource_logs');

      local logs =
        logPanel.new('Logs')
        + logPanel.queryOptions.withDatasource('loki', '$datasource_logs') + logPanel.options.withShowLabels(true)
        + logPanel.queryOptions.withTargets([lokiTarget('{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"')]);

      local rate =
        timeSeriesBase('Rate', 'ops', min=0, calcs=['lastNotNull'])
        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(http_server_requests_seconds_count{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod"}[1m]))', 'HTTP')]);

      local successRate =
        timeSeriesBase('Success Rate (non-4|5xx responses)', 'ops', min=0, calcs=['lastNotNull'])
        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(http_server_requests_seconds_count{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", status=~"[4-5].*"}[1m]))', 'HTTP - 5xx|4xx')]);

      local duration =
        timeSeriesBase('Duration', 's', min=0, calcs=['lastNotNull'])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(rate(http_server_requests_seconds_sum{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", status!~"5.."}[1m]))/sum(rate(http_server_requests_seconds_count{job=~"$job", namespace=~"$namespace", pod=~"$pod", status!~"5.."}[1m]))', 'HTTP - AVG'),
          promTarget('max(http_server_requests_seconds_max{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", status!~"5.."})', 'HTTP - MAX'),
        ]);

      local statBase(title, expr) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit('percent') + statPanel.standardOptions.withDecimals(2)
        + statPanel.options.withColorMode('value') + statPanel.options.withGraphMode('area')
        + statPanel.options.reduceOptions.withCalcs(['mean'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds($._config.templates.L1.k8sApps.javaActuator.panel.thresholds))
        + statPanel.queryOptions.withTargets([promTarget(expr)]);

      local heapUsed = statBase('Heap used', 'sum(jvm_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="heap"})*100/sum(jvm_memory_max_bytes{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="heap"})');
      local NonHeapUsed = statBase('Non-Heap used', 'sum(jvm_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="nonheap"})*100/sum(jvm_memory_max_bytes{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="nonheap"})');
      local memCalcs = ['max', 'lastNotNull'];

      local JvmHeap =
        timeSeriesBase('JVM Heap', 'bytes', min=0, calcs=memCalcs)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(jvm_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="heap"}) by ($view)', 'used - {{$view}}'),
          promTarget('sum(jvm_memory_committed_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="heap"}) by ($view)', 'committed - {{$view}}'),
          promTarget('sum(jvm_memory_max_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="heap"}) by ($view)', 'max - {{$view}}'),
        ]);

      local JvmNonHeap =
        timeSeriesBase('JVM Non-Heap', 'bytes', min=0, calcs=memCalcs)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(jvm_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="nonheap"}) by ($view)', 'used - {{$view}}'),
          promTarget('sum(jvm_memory_committed_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="nonheap"}) by ($view)', 'committed - {{$view}}'),
          promTarget('sum(jvm_memory_max_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="nonheap"}) by ($view)', 'max - {{$view}}'),
        ]);

      local total =
        timeSeriesBase('JVM Total', 'bytes', calcs=memCalcs)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(jvm_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'used - {{$view}}'),
          promTarget('sum(jvm_memory_committed_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'committed - {{$view}}'),
          promTarget('sum(jvm_memory_max_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'max - {{$view}}'),
          promTarget('sum(process_memory_vss_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'vss - {{$view}}'),
          promTarget('sum(process_memory_rss_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'rss - {{$view}}'),
          promTarget('sum(process_memory_pss_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'pss - {{$view}}'),
          promTarget('sum(process_memory_swap_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'swap - {{$view}}'),
          promTarget('sum(process_memory_swappss_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'swappss - {{$view}}'),
          promTarget('sum(process_memory_pss_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) + sum(process_memory_swap_bytes{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'phys (pss+swap) - {{$view}}'),
        ]);

      local threads =
        timeSeriesBase('Threads', min=0, calcs=memCalcs)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(jvm_threads_live{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) or sum(jvm_threads_live_threads{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) ', 'live - {{$view}}'),
          promTarget('sum(jvm_threads_daemon{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"})  by ($view)  or sum(jvm_threads_daemon_threads{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'daemon - {{$view}}'),
          promTarget('sum(jvm_threads_peak{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"})  by ($view)  or sum(jvm_threads_peak_threads{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'peak - {{$view}}'),
          promTarget('sum(process_threads{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"})  by ($view)', 'process - {{$view}}'),
        ]);

      local threadsStates =
        timeSeriesBase('Thread States', calcs=memCalcs, overrides=[
          colorOverride('/blocked/', color.red),
          colorOverride('/waiting/', color.yellow),
          colorOverride('/new/', color.pink),
          colorOverride('/runnable/', color.green),
          colorOverride('/terminated/', color.purple),
          colorOverride('/timed-waiting/', color.orange),
        ])
        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(jvm_threads_states_threads{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"})  by (state, $view)', '{{state}} - {{$view}}')]);

      local fileDescriptions =
        timeSeriesBase('File Descriptors', min=0, log10=true, calcs=memCalcs)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(process_open_fds{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'open - {{$view}}'),
          promTarget('sum(process_max_fds{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'max - {{$view}}'),
          promTarget('sum(process_files_open{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) or sum(process_files_open_files{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'open - {{$view}}'),
          promTarget('sum(process_files_max{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) or sum(process_files_max_files{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'max - {{$view}}'),
        ]);

      local logEvents =
        timeSeriesBase('Log Events (1m)', min=0, calcs=memCalcs, overrides=[
          colorOverride('/error/', color.red),
          colorOverride('/warn/', color.yellow),
          colorOverride('/trace/', color.lightblue),
          colorOverride('/info/', color.green),
          colorOverride('/debug/', color.blue),
        ])
        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(increase(logback_events_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by (level, $view)', '{{level}} - {{$view}}')]);

      local jvmMemoryPoolHeap =
        timeSeriesBase('$jvm_memory_pool_heap', 'bytes', min=0, calcs=memCalcs, repeat='jvm_memory_pool_heap', maxPerRow=3)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(jvm_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="$jvm_memory_pool_heap"}) by ($view)', 'used - {{$view}}'),
          promTarget('sum(jvm_memory_committed_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="$jvm_memory_pool_heap"}) by ($view)', 'commited - {{$view}}'),
          promTarget('sum(jvm_memory_max_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="$jvm_memory_pool_heap"}) by ($view)', 'max - {{$view}}'),
        ]);

      local jvmMemoryPoolNonHeap =
        timeSeriesBase('$jvm_memory_pool_nonheap', 'bytes', min=0, calcs=memCalcs, repeat='jvm_memory_pool_nonheap', maxPerRow=3)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(jvm_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="${jvm_memory_pool_nonheap:raw}"}) by ($view)', 'used - {{$view}}'),
          promTarget('sum(jvm_memory_committed_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="${jvm_memory_pool_nonheap:raw}"}) by ($view)', 'commited - {{$view}}'),
          promTarget('sum(jvm_memory_max_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="${jvm_memory_pool_nonheap:raw}"}) by ($view)', 'max - {{$view}}'),
        ]);

      local collections =
        timeSeriesBase('Collections', 'ops', min=0)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(rate(jvm_gc_pause_seconds_count{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by (action, cause, $view)', '{{action}} ({{cause}}) - {{$view}}')]);

      local pauseDurations =
        timeSeriesBase('Pause Durations', 's', min=0)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(rate(jvm_gc_pause_seconds_sum{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by (action, cause, $view) /sum(rate(jvm_gc_pause_seconds_count{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by (action, cause, $view)', 'avg {{action}} ({{cause}}) - {{$view}}'),
          promTarget('sum(jvm_gc_pause_seconds_max{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by (action, cause, $view)', 'max {{action}} ({{cause}}) - {{$view}}'),
        ]);

      local allocatedPromoted =
        timeSeriesBase('Allocated/Promoted', 'bytes', min=0)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(rate(jvm_gc_memory_allocated_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by ($view)', 'allocated - {{$view}}'),
          promTarget('sum(rate(jvm_gc_memory_promoted_bytes_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by ($view)', 'promoted - {{$view}}'),
        ]);

      local classesLoaded =
        timeSeriesBase('Classes loaded', min=0)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(jvm_classes_loaded{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) or sum(jvm_classes_loaded_classes{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', 'loaded - {{$view}}')]);

      local classDelta =
        timeSeriesBase('Class delta (5m)')
        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(delta(jvm_classes_loaded{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[5m])) by ($view) or sum(delta(jvm_classes_loaded_classes{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[5m])) by ($view)', 'delta - {{$view}}')]);

      local directBuffersMemoryUsedBytes =
        timeSeriesBase('Direct Buffers (Memory Used Bytes)', 'bytes', min=0)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(jvm_buffer_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="direct"}) by ($view)', 'used - {{$view}}'),
          promTarget('sum(jvm_buffer_total_capacity_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="direct"}) by ($view)', 'capacity - {{$view}}'),
        ]);

      local directBuffersCount =
        timeSeriesBase('Direct Buffers (Count)', min=0)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(jvm_buffer_count{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="direct"}) by ($view) or sum(jvm_buffer_count_buffers{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="direct"}) by ($view)', 'count - {{$view}}')]);

      local mappedBuffersMemoryUsedBytes =
        timeSeriesBase('Mapped Buffers (Memory Used Bytes)', 'bytes', min=0)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(jvm_buffer_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="mapped"}) by ($view)', 'used - {{$view}}'),
          promTarget('sum(jvm_buffer_total_capacity_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="mapped"}) by ($view)', 'capacity - {{$view}}'),
        ]);

      local mappedBuffersCount =
        timeSeriesBase('Mapped Buffers (Count)', min=0)
        + timeSeriesPanel.queryOptions.withTargets([promTarget('sum(jvm_buffer_count{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="mapped"}) by ($view) or sum(jvm_buffer_count_buffers{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="mapped"}) by ($view)', 'count - {{$view}}')]);

      local templates =
        [$.grafanaTemplates.datasourceTemplate()]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.datasourceLogsTemplate()] else [])
        + [
          $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
          $.grafanaTemplates.jobTemplate('label_values(jvm_memory_used_bytes{cluster="$cluster"}, job)'),
          $.grafanaTemplates.viewByTemplate('pod,container'),
          $.grafanaTemplates.namespaceTemplate('label_values(jvm_memory_used_bytes{cluster="$cluster", job=~"$job"}, namespace)'),
          $.grafanaTemplates.podTemplate('label_values(jvm_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace"}, pod)'),
          $.grafanaTemplates.containerTemplate('label_values(jvm_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace"}, container)'),
          $.grafanaTemplates.baseTemplate('jvm_memory_pool_heap', 'JVM Memory Pools Heap', 'label_values(jvm_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", area="heap"},id)'),
          $.grafanaTemplates.baseTemplate('jvm_memory_pool_nonheap', 'JVM Memory Pools Non-Heap', 'label_values(jvm_memory_used_bytes{cluster="$cluster", job=~"$job", namespace=~"$namespace", area="nonheap"},id)'),
        ]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.searchTemplate()] else []);

      local logsPanels = [
        row.new('Logs') + { gridPos: { x: 0, y: 108, w: 24, h: 1 } },
        count { gridPos: { x: 0, y: 109, w: 24, h: 5 } },
        logs { gridPos: { x: 0, y: 114, w: 24, h: 13 } },
      ];

      local panels = [
        row.new('CPU Usage') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        cpu { gridPos: { x: 0, y: 1, w: 24, h: 7 } },
        row.new('Memory Usage') + { gridPos: { x: 0, y: 8, w: 24, h: 1 } },
        memory { gridPos: { x: 0, y: 9, w: 24, h: 7 } },
        row.new('Network Bandwidth') + { gridPos: { x: 0, y: 16, w: 24, h: 1 } },
        bandwidth { gridPos: { x: 0, y: 17, w: 24, h: 7 } },
        row.new('Network Rate') + { gridPos: { x: 0, y: 24, w: 24, h: 1 } },
        rate { gridPos: { x: 0, y: 25, w: 8, h: 7 } },
        successRate { gridPos: { x: 8, y: 25, w: 8, h: 7 } },
        duration { gridPos: { x: 16, y: 25, w: 8, h: 7 } },
        row.new('Network Drops') + { gridPos: { x: 0, y: 32, w: 24, h: 1 } },
        drops { gridPos: { x: 0, y: 33, w: 24, h: 7 } },
        row.new('Overview') + { gridPos: { x: 0, y: 40, w: 24, h: 1 } },
        heapUsed { gridPos: { x: 0, y: 41, w: 12, h: 3 } },
        NonHeapUsed { gridPos: { x: 12, y: 41, w: 12, h: 3 } },
        row.new('JVM Memory') + { gridPos: { x: 0, y: 44, w: 24, h: 1 } },
        JvmHeap { gridPos: { x: 0, y: 45, w: 8, h: 7 } },
        JvmNonHeap { gridPos: { x: 8, y: 45, w: 8, h: 7 } },
        total { gridPos: { x: 16, y: 45, w: 8, h: 7 } },
        row.new('JVM Misc') + { gridPos: { x: 0, y: 52, w: 24, h: 1 } },
        threads { gridPos: { x: 0, y: 53, w: 8, h: 8 } },
        threadsStates { gridPos: { x: 8, y: 53, w: 8, h: 8 } },
        fileDescriptions { gridPos: { x: 16, y: 53, w: 8, h: 8 } },
        logEvents { gridPos: { x: 0, y: 61, w: 24, h: 7 } },
        row.new('JVM Memory Pools(Heap)') + { gridPos: { x: 0, y: 68, w: 24, h: 1 } },
        jvmMemoryPoolHeap { gridPos: { x: 0, y: 69, w: 8, h: 7 } },
        row.new('JVM Memory Pools(Non-Heap)') + { gridPos: { x: 0, y: 76, w: 24, h: 1 } },
        jvmMemoryPoolNonHeap { gridPos: { x: 0, y: 77, w: 8, h: 7 } },
        row.new('Garbage Collection') + { gridPos: { x: 0, y: 84, w: 24, h: 1 } },
        collections { gridPos: { x: 0, y: 85, w: 8, h: 7 } },
        pauseDurations { gridPos: { x: 8, y: 85, w: 8, h: 7 } },
        allocatedPromoted { gridPos: { x: 16, y: 85, w: 8, h: 7 } },
        row.new('Classloading') + { gridPos: { x: 0, y: 92, w: 24, h: 1 } },
        classesLoaded { gridPos: { x: 0, y: 93, w: 12, h: 7 } },
        classDelta { gridPos: { x: 12, y: 93, w: 12, h: 7 } },
        row.new('Buffer Pools') + { gridPos: { x: 0, y: 100, w: 24, h: 1 } },
        directBuffersMemoryUsedBytes { gridPos: { x: 0, y: 101, w: 6, h: 7 } },
        directBuffersCount { gridPos: { x: 6, y: 101, w: 6, h: 7 } },
        mappedBuffersMemoryUsedBytes { gridPos: { x: 12, y: 101, w: 6, h: 7 } },
        mappedBuffersCount { gridPos: { x: 18, y: 101, w: 6, h: 7 } },
      ] + (if $._config.grafanaDashboards.isLoki then logsPanels else []);

      dashboard.new('Java Actuator')
      + dashboard.withUid($._config.grafanaDashboards.ids.javaActuator)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables(templates)
      + dashboard.withPanels(panels),
  },
}
