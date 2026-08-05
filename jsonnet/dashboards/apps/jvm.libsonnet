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

/* JVM dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    jvm:
      local color = $._config.grafanaDashboards.color;

      local promTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local timeSeriesBase(title, unit=null, min=null, max=null, calcs=[]) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + (if min != null then timeSeriesPanel.standardOptions.withMin(min) else {})
        + (if max != null then timeSeriesPanel.standardOptions.withMax(max) else {})
        + (if std.length(calcs) > 0 then
             timeSeriesPanel.options.legend.withDisplayMode('list') + timeSeriesPanel.options.legend.withCalcs(calcs)
           else {});

      local runtime =
        statPanel.new('Runtime')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit('none')
        + statPanel.options.withColorMode('value')
        + statPanel.options.withGraphMode('none')
        + statPanel.options.reduceOptions.withCalcs(['first'])
        + statPanel.options.reduceOptions.withFields('version')
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps([{ color: color.green, value: null }, { color: color.red, value: 80 }])
        + statPanel.queryOptions.withTargets([
          prometheus.withExpr('jvm_info{namespace="$namespace",pod="$pod"}') + prometheus.withFormat('table') + prometheus.withLegendFormat('{{version}}'),
        ]);

      local startTime =
        statPanel.new('Start time')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit('dateTimeAsIso')
        + statPanel.options.withColorMode('value')
        + statPanel.options.withGraphMode('none')
        + statPanel.options.reduceOptions.withCalcs(['mean'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps([{ color: color.green, value: null }])
        + statPanel.standardOptions.withMappings([
          { type: 'special', options: { match: 'null', result: { text: 'N/A' } } },
        ])
        + statPanel.queryOptions.withTargets([
          promTarget('process_start_time_seconds{namespace="$namespace",pod="$pod"}*1000'),
        ]);

      local heapUsed =
        statPanel.new('Heap used')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit('percent')
        + statPanel.standardOptions.withDecimals(2)
        + statPanel.options.withColorMode('value')
        + statPanel.options.withGraphMode('none')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps([{ color: color.green, value: null }, { color: color.orange, value: 70 }, { color: color.red, value: 90 }])
        + statPanel.queryOptions.withTargets([
          promTarget('sum(jvm_memory_bytes_used{ namespace="$namespace", pod="$pod", area="heap"})*100/sum(jvm_memory_bytes_max{ namespace="$namespace", pod="$pod", area="heap"})'),
        ]);

      local nonHeapUsed =
        statPanel.new('Non-Heap used')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit('percent')
        + statPanel.standardOptions.withDecimals(2)
        + statPanel.options.withColorMode('value')
        + statPanel.options.withGraphMode('none')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps([{ color: color.green, value: null }])
        + statPanel.standardOptions.withMappings([
          { type: 'special', options: { match: 'null', result: { text: 'N/A' } } },
          { type: 'range', options: { from: -$._config.grafanaDashboards.constants.infinity, to: 0, result: { text: 'N/A' } } },
        ])
        + statPanel.queryOptions.withTargets([
          promTarget('sum(jvm_memory_bytes_used{namespace="$namespace",pod="$pod", area="nonheap"})*100/sum(jvm_memory_bytes_max{namespace="$namespace",pod="$pod", area="nonheap"})'),
        ]);

      local jvmHeap =
        timeSeriesBase('JVM Heap', 'bytes', calcs=['max', 'lastNotNull'])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(jvm_memory_bytes_used{ namespace="$namespace", pod="$pod",area="heap"})', 'used'),
          promTarget('sum(jvm_memory_bytes_committed{ namespace="$namespace", pod="$pod",area="heap"})', 'committed'),
          promTarget('sum(jvm_memory_bytes_max{ namespace="$namespace", pod="$pod",area="heap"})', 'max'),
        ]);

      local jvmNonHeap =
        timeSeriesBase('JVM Non-Heap', 'bytes', calcs=['max', 'lastNotNull'])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(jvm_memory_bytes_used{namespace="$namespace",pod="$pod", area="nonheap"})', 'used'),
          promTarget('sum(jvm_memory_bytes_committed{namespace="$namespace",pod="$pod", area="nonheap"})', 'committed'),
          promTarget('sum(jvm_memory_bytes_max{namespace="$namespace",pod="$pod", area="nonheap"})', 'max'),
        ]);

      local jvmTotal =
        timeSeriesBase('JVM Total', 'bytes', calcs=['max', 'lastNotNull'])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('sum(jvm_memory_bytes_used{namespace="$namespace",pod="$pod"})', 'used'),
          promTarget('sum(jvm_memory_bytes_committed{namespace="$namespace",pod="$pod"})', 'committed'),
        ]);

      local cpu =
        timeSeriesBase('CPU Usage', 'percent', min=0, max=100, calcs=['max', 'lastNotNull'])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('rate(process_cpu_seconds_total{namespace="$namespace",pod="$pod"}[1m])', 'cpu_seconds'),
        ]);

      local threads =
        timeSeriesBase('Threads', calcs=['max', 'lastNotNull'])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('jvm_threads_current{namespace="$namespace",pod="$pod"}', 'live'),
          promTarget('jvm_threads_daemon{namespace="$namespace",pod="$pod"}', 'daemon'),
          promTarget('jvm_threads_peak{namespace="$namespace",pod="$pod"}', 'peak'),
          promTarget('jvm_threads_deadlocked{namespace="$namespace",pod="$pod"}', 'deadlocked'),
        ]);

      local threadStates =
        timeSeriesBase('Thread States', calcs=['max', 'lastNotNull'])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('jvm_threads_state{namespace="$namespace",pod="$pod"}', '{{state}}'),
        ]);

      local fileDesc =
        timeSeriesBase('File Descriptors', calcs=['max', 'lastNotNull'])
        + timeSeriesPanel.fieldConfig.defaults.custom.scaleDistribution.withType('log')
        + timeSeriesPanel.fieldConfig.defaults.custom.scaleDistribution.withLog(10)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('process_open_fds{namespace="$namespace",pod="$pod"}', 'open'),
        ]);

      local heap =
        timeSeriesBase('Heap', 'bytes', min=0, calcs=['max', 'lastNotNull'])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('jvm_memory_bytes_used{namespace="$namespace",pod="$pod",area="heap"}', 'used'),
          promTarget('jvm_memory_bytes_committed{namespace="$namespace",pod="$pod",area="heap"}', 'commited'),
        ]);

      local nonHeap =
        timeSeriesBase('Non-heap', 'bytes', min=0, calcs=['max', 'lastNotNull'])
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('jvm_memory_bytes_used{namespace="$namespace",pod="$pod",area="nonheap"}', 'used'),
          promTarget('jvm_memory_bytes_committed{namespace="$namespace",pod="$pod",area="nonheap"}', 'commited'),
        ]);

      local gcOps =
        timeSeriesBase('GC operations', 'ops')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('rate(jvm_gc_collection_seconds_count{namespace="$namespace",pod="$pod"}[1m])', '{{gc}}'),
        ]);

      local poolAllocations =
        timeSeriesBase('Pool allocations', 'Bps')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('rate(jvm_memory_pool_allocated_bytes_total{namespace="$namespace",pod="$pod"}[1m])', '{{pool}}'),
        ]);

      local classes =
        timeSeriesBase('Classes loaded', min=0)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('jvm_classes_loaded{namespace="$namespace",pod="$pod"}', 'loaded total'),
        ]);

      local classesDelta =
        timeSeriesBase('Class loaded delta')
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('delta(jvm_classes_loaded{namespace="$namespace",pod="$pod"}[1m])', 'delta-1m'),
        ]);

      local directBuffers =
        timeSeriesBase('Direct Buffers', 'bytes', min=0)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('jvm_buffer_pool_used_bytes{namespace="$namespace",pod="$pod", pool="direct"}', 'used'),
          promTarget('jvm_buffer_pool_capacity_bytes{namespace="$namespace",pod="$pod", pool="direct"}', 'capacity'),
        ]);

      local mappedBuffers =
        timeSeriesBase('Mapped Buffers', 'bytes', min=0)
        + timeSeriesPanel.queryOptions.withTargets([
          promTarget('jvm_buffer_pool_used_buffers{namespace="$namespace",pod="$pod", pool="mapped"}', 'used'),
          promTarget('jvm_buffer_pool_capacity_bytes{namespace="$namespace",pod="$pod", pool="mapped"}', 'capacity'),
        ]);

      local panels = [
        row.new('Quick Facts') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        runtime { gridPos: { x: 0, y: 1, w: 6, h: 3 } },
        startTime { gridPos: { x: 6, y: 1, w: 6, h: 3 } },
        heapUsed { gridPos: { x: 12, y: 1, w: 6, h: 3 } },
        nonHeapUsed { gridPos: { x: 18, y: 1, w: 6, h: 3 } },
        row.new('Memory') + { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
        jvmHeap { gridPos: { x: 0, y: 5, w: 9, h: 6 } },
        jvmNonHeap { gridPos: { x: 9, y: 5, w: 7, h: 6 } },
        jvmTotal { gridPos: { x: 16, y: 5, w: 8, h: 6 } },
        row.new('JVM Misc') + { gridPos: { x: 0, y: 11, w: 24, h: 1 } },
        cpu { gridPos: { x: 0, y: 12, w: 6, h: 7 } },
        threads { gridPos: { x: 6, y: 12, w: 6, h: 7 } },
        threadStates { gridPos: { x: 12, y: 12, w: 6, h: 7 } },
        fileDesc { gridPos: { x: 18, y: 12, w: 6, h: 7 } },
        row.new('JVM Memory Pools') + { gridPos: { x: 0, y: 19, w: 24, h: 1 } },
        heap { gridPos: { x: 0, y: 20, w: 12, h: 6 } },
        nonHeap { gridPos: { x: 12, y: 20, w: 12, h: 6 } },
        row.new('Garbage Collection') + { gridPos: { x: 0, y: 26, w: 24, h: 1 } },
        gcOps { gridPos: { x: 0, y: 27, w: 12, h: 6 } },
        poolAllocations { gridPos: { x: 12, y: 27, w: 12, h: 6 } },
        row.new('Classloading') + { gridPos: { x: 0, y: 33, w: 24, h: 1 } },
        classes { gridPos: { x: 0, y: 34, w: 12, h: 7 } },
        classesDelta { gridPos: { x: 12, y: 34, w: 12, h: 7 } },
        row.new('Buffer Pools') + { gridPos: { x: 0, y: 41, w: 24, h: 1 } },
        directBuffers { gridPos: { x: 0, y: 42, w: 12, h: 6 } },
        mappedBuffers { gridPos: { x: 12, y: 42, w: 12, h: 6 } },
      ];

      dashboard.new('JVM')
      + dashboard.withUid($._config.grafanaDashboards.ids.jvm)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sVMs)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.namespaceTemplate('label_values(jvm_info{}, namespace)', includeAll=false, multi=false),
        $.grafanaTemplates.podTemplate('label_values(jvm_info{namespace=~"$namespace"}, pod)', includeAll=false, multi=false),
      ])
      + dashboard.withPanels(panels),
  },
}
