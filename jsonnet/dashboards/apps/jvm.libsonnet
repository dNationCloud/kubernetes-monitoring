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
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;
local singlestat = grafana.singlestat;

{
  grafanaDashboards+:: {
    jvm:
      local runtime =
        statPanel.new(
          title='Runtime',
          datasource='$datasource',
          graphMode='none',
          fields='version',
          reducerFunction='first',
        )
        .addThresholds(
          [
            { color: $._config.grafanaDashboards.color.green, value: null },
            { color: $._config.grafanaDashboards.color.red, value: 80 },
          ]
        )
        .addTarget(prometheus.target('jvm_info{namespace="$namespace",pod="$pod"}', legendFormat='{{version}}', format='table'));

      local startTime =
        singlestat.new(
          title='Start time',
          datasource='$datasource',
          format='dateTimeAsIso',
          colorValue=true,
        )
        .addTarget(prometheus.target('process_start_time_seconds{namespace="$namespace",pod="$pod"}*1000', legendFormat=''));

      local heapUsed =
        singlestat.new(
          title='Heap used',
          datasource='$datasource',
          colorValue=true,
          format='percent',
          decimals=2,
          thresholds='70,90',
          valueName='current',
        )
        .addTarget(prometheus.target('sum(jvm_memory_bytes_used{ namespace="$namespace", pod="$pod", area="heap"})*100/sum(jvm_memory_bytes_max{ namespace="$namespace", pod="$pod", area="heap"})'));

      local nonHeapUsed =
        singlestat.new(
          title='Non-Heap used',
          datasource='$datasource',
          colorValue=true,
          format='percent',
          mappingType=2,
          valueName='current',
          decimals=2,
          rangeMaps=[
            {
              from: 'null',
              text: 'N/A',
              to: 'null',
            },
            {
              from: -$._config.grafanaDashboards.constants.infinity,
              text: 'N/A',
              to: 0,
            },
          ],
        )
        .addTarget(prometheus.target('sum(jvm_memory_bytes_used{namespace="$namespace",pod="$pod", area="nonheap"})*100/sum(jvm_memory_bytes_max{namespace="$namespace",pod="$pod", area="nonheap"})'));

      local jvmHeap =
        graphPanel.new(
          title='JVM Heap',
          datasource='$datasource',
          formatY1='bytes',
          formatY2='short',
          legend_values=true,
          legend_max=true,
          legend_current=true,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_memory_bytes_used{ namespace="$namespace", pod="$pod",area="heap"})', legendFormat='used'),
            prometheus.target('sum(jvm_memory_bytes_committed{ namespace="$namespace", pod="$pod",area="heap"})', legendFormat='committed'),
            prometheus.target('sum(jvm_memory_bytes_max{ namespace="$namespace", pod="$pod",area="heap"})', legendFormat='max'),
          ],
        );

      local jvmNonHeap =
        graphPanel.new(
          title='JVM Non-Heap',
          datasource='$datasource',
          formatY1='bytes',
          formatY2='short',
          legend_values=true,
          legend_max=true,
          legend_current=true,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_memory_bytes_used{namespace="$namespace",pod="$pod", area="nonheap"})', legendFormat='used'),
            prometheus.target('sum(jvm_memory_bytes_committed{namespace="$namespace",pod="$pod", area="nonheap"})', legendFormat='committed'),
            prometheus.target('sum(jvm_memory_bytes_max{namespace="$namespace",pod="$pod", area="nonheap"})', legendFormat='max'),
          ],
        );

      local jvmTotal =
        graphPanel.new(
          title='JVM Total',
          datasource='$datasource',
          formatY1='bytes',
          formatY2='short',
          legend_values=true,
          legend_max=true,
          legend_current=true,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_memory_bytes_used{namespace="$namespace",pod="$pod"})', legendFormat='used'),
            prometheus.target('sum(jvm_memory_bytes_committed{namespace="$namespace",pod="$pod"})', legendFormat='committed'),
          ],
        );

      local cpu =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          format='percent',
          min=0,
          max=100,
          legend_values=true,
          legend_max=true,
          legend_current=true,
        )
        .addTarget(prometheus.target('rate(process_cpu_seconds_total{namespace="$namespace",pod="$pod"}[1m])', legendFormat='cpu_seconds'));

      local threads =
        graphPanel.new(
          title='Threads',
          datasource='$datasource',
          legend_max=true,
          legend_current=true,
        )
        .addTargets(
          [
            prometheus.target('jvm_threads_current{namespace="$namespace",pod="$pod"}', legendFormat='live'),
            prometheus.target('jvm_threads_daemon{namespace="$namespace",pod="$pod"}', legendFormat='daemon'),
            prometheus.target('jvm_threads_peak{namespace="$namespace",pod="$pod"}', legendFormat='peak'),
            prometheus.target('jvm_threads_deadlocked{namespace="$namespace",pod="$pod"}', legendFormat='deadlocked'),
          ],
        );

      local threadStates =
        graphPanel.new(
          title='Thread States',
          datasource='$datasource',
          legend_values=true,
          legend_max=true,
          legend_current=true,
        )
        .addTarget(prometheus.target('jvm_threads_state{namespace="$namespace",pod="$pod"}', legendFormat='{{state}}'));

      local fileDesc =
        graphPanel.new(
          title='File Descriptors',
          datasource='$datasource',
          legend_values=true,
          legend_max=true,
          legend_current=true,
          logBase1Y=10,
        )
        .addTarget(prometheus.target('process_open_fds{namespace="$namespace",pod="$pod"}', legendFormat='open'));

      local heap =
        graphPanel.new(
          title='Heap',
          datasource='$datasource',
          formatY1='bytes',
          formatY2='short',
          legend_values=true,
          legend_max=true,
          legend_current=true,
          min=0,
        )
        .addTargets(
          [
            prometheus.target('jvm_memory_bytes_used{namespace="$namespace",pod="$pod",area="heap"}', legendFormat='used'),
            prometheus.target('jvm_memory_bytes_committed{namespace="$namespace",pod="$pod",area="heap"}', legendFormat='commited'),
          ],
        );

      local nonHeap =
        graphPanel.new(
          title='Non-heap',
          datasource='$datasource',
          formatY1='bytes',
          formatY2='short',
          legend_values=true,
          legend_max=true,
          legend_current=true,
          min=0,
        )
        .addTargets(
          [
            prometheus.target('jvm_memory_bytes_used{namespace="$namespace",pod="$pod",area="nonheap"}', legendFormat='used'),
            prometheus.target('jvm_memory_bytes_committed{namespace="$namespace",pod="$pod",area="nonheap"}', legendFormat='commited'),
          ],
        );

      local gcOps =
        graphPanel.new(
          title='GC operations',
          datasource='$datasource',
          formatY1='ops',
          formatY2='short',
        )
        .addTarget(prometheus.target('rate(jvm_gc_collection_seconds_count{namespace="$namespace",pod="$pod"}[1m])', legendFormat='{{gc}}'));

      local poolAllocations =
        graphPanel.new(
          title='Pool allocations',
          datasource='$datasource',
          formatY1='Bps',
          formatY2='short',
        )
        .addTarget(prometheus.target('rate(jvm_memory_pool_allocated_bytes_total{namespace="$namespace",pod="$pod"}[1m])', legendFormat='{{pool}}'));

      local classes =
        graphPanel.new(
          title='Classes loaded',
          datasource='$datasource',
          min=0,
        )
        .addTarget(prometheus.target('jvm_classes_loaded{namespace="$namespace",pod="$pod"}', legendFormat='loaded total'));

      local classesDelta =
        graphPanel.new(
          title='Class loaded delta',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('delta(jvm_classes_loaded{namespace="$namespace",pod="$pod"}[1m])', legendFormat='delta-1m'));

      local directBuffers =
        graphPanel.new(
          title='Direct Buffers',
          datasource='$datasource',
          formatY1='bytes',
          formatY2='short',
          min=0,
        )
        .addTargets(
          [
            prometheus.target('jvm_buffer_pool_used_bytes{namespace="$namespace",pod="$pod", pool="direct"}', legendFormat='used'),
            prometheus.target('jvm_buffer_pool_capacity_bytes{namespace="$namespace",pod="$pod", pool="direct"}', legendFormat='capacity'),
          ],
        );

      local mappedBuffers =
        graphPanel.new(
          title='Mapped Buffers',
          datasource='$datasource',
          formatY1='bytes',
          formatY2='short',
          min=0,
        )
        .addTargets(
          [
            prometheus.target('jvm_buffer_pool_used_buffers{namespace="$namespace",pod="$pod", pool="mapped"}', legendFormat='used'),
            prometheus.target('jvm_buffer_pool_capacity_bytes{namespace="$namespace",pod="$pod", pool="mapped"}', legendFormat='capacity'),
          ],
        );

      local panels = [
        row.new('Quick Facts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        runtime { gridPos: { x: 0, y: 1, w: 6, h: 3 } },
        startTime { gridPos: { x: 6, y: 1, w: 6, h: 3 } },
        heapUsed { gridPos: { x: 12, y: 1, w: 6, h: 3 } },
        nonHeapUsed { gridPos: { x: 18, y: 1, w: 6, h: 3 } },
        row.new('Memory') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
        jvmHeap { gridPos: { x: 0, y: 5, w: 9, h: 6 } },
        jvmNonHeap { gridPos: { x: 9, y: 5, w: 7, h: 6 } },
        jvmTotal { gridPos: { x: 16, y: 5, w: 8, h: 6 } },
        row.new('JVM Misc') { gridPos: { x: 0, y: 11, w: 24, h: 1 } },
        cpu { gridPos: { x: 0, y: 12, w: 6, h: 7 } },
        threads { gridPos: { x: 6, y: 12, w: 6, h: 7 } },
        threadStates { gridPos: { x: 12, y: 12, w: 6, h: 7 } },
        fileDesc { gridPos: { x: 18, y: 12, w: 6, h: 7 } },
        row.new('JVM Memory Pools') { gridPos: { x: 0, y: 19, w: 24, h: 1 } },
        heap { gridPos: { x: 0, y: 20, w: 12, h: 6 } },
        nonHeap { gridPos: { x: 12, y: 20, w: 12, h: 6 } },
        row.new('Garbage Collection') { gridPos: { x: 0, y: 26, w: 24, h: 1 } },
        gcOps { gridPos: { x: 0, y: 27, w: 12, h: 6 } },
        poolAllocations { gridPos: { x: 12, y: 27, w: 12, h: 6 } },
        row.new('Classloading') { gridPos: { x: 0, y: 33, w: 24, h: 1 } },
        classes { gridPos: { x: 0, y: 34, w: 12, h: 7 } },
        classesDelta { gridPos: { x: 12, y: 34, w: 12, h: 7 } },
        row.new('Buffer Pools') { gridPos: { x: 0, y: 41, w: 24, h: 1 } },
        directBuffers { gridPos: { x: 0, y: 42, w: 12, h: 6 } },
        mappedBuffers { gridPos: { x: 12, y: 42, w: 12, h: 6 } },
      ];

      dashboard.new(
        'JVM',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sVMs,
        uid=$._config.grafanaDashboards.ids.jvm,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.namespaceTemplate('label_values(jvm_info{}, namespace)', includeAll=false, multi=false),
        $.grafanaTemplates.podTemplate('label_values(jvm_info{namespace=~"$namespace"}, pod)', includeAll=false, multi=false),
      ])
      .addPanels(panels),
  },
}
