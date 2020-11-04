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

/* K8s java-actuator dashboard */
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local loki = grafana.loki;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local logPanel = grafana.logPanel;
local statPanel = grafana.statPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    'java-actuator':
      local datasourceTemplate =
        template.datasource(
          name='datasource',
          label='Datasource',
          query='prometheus',
          current=null,
        );

      local datasourceLogsTemplate =
        template.datasource(
          name='datasource_logs',
          label='Logs datasource',
          query='loki',
          current=null,
        );

      local clusterTemplate =
        template.new(
          name='cluster',
          label='Cluster',
          datasource='$datasource',
          query='label_values(node_uname_info, cluster)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local jobTemplate =
        template.new(
          name='job',
          label='Job',
          datasource='$datasource',
          query='label_values(jvm_memory_used_bytes{cluster=~"$cluster"}, job)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          includeAll=true,
          multi=true,
        );

      local viewByTemplate =
        template.custom(
          name='view',
          label='View by',
          query='pod,container',
          current='container',
        );

      local namespaceTemplate =
        template.new(
          name='namespace',
          label='Namespace',
          datasource='$datasource',
          query='label_values(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job"}, namespace)',
          refresh=$._config.dashboardCommon.templateRefresh,
          sort=$._config.dashboardCommon.templateSort,
          includeAll=true,
          multi=true,
        );

      local podTemplate =
        template.new(
          name='pod',
          label='Pod',
          datasource='$datasource',
          query='label_values(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace"}, pod)',
          refresh=$._config.dashboardCommon.templateRefresh,
          sort=$._config.dashboardCommon.templateSort,
          includeAll=true,
          multi=true,
        );

      local containerTemplate =
        template.new(
          name='container',
          label='Container',
          datasource='$datasource',
          query='label_values(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace"}, container)',
          refresh=$._config.dashboardCommon.templateRefresh,
          sort=$._config.dashboardCommon.templateSort,
          includeAll=true,
          multi=true,
        );

      local searchTemplate =
        template.text(
          name='search',
          label='Logs Search',
        );

      local memoryPoolsHeap =
        template.new(
          name='jvm_memory_pool_heap',
          label='JVM Memory Pools Heap',
          datasource='$datasource',
          query='label_values(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", area="heap"},id)',
          refresh=$._config.dashboardCommon.templateRefresh,
          sort=$._config.dashboardCommon.templateSort,
          includeAll=true,
          multi=true,
        );

      local memoryPoolsNonHeap =
        template.new(
          name='jvm_memory_pool_nonheap',
          label='JVM Memory Pools Non-Heap',
          datasource='$datasource',
          query='label_values(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", area="nonheap"},id)',
          refresh=$._config.dashboardCommon.templateRefresh,
          sort=$._config.dashboardCommon.templateSort,
          includeAll=true,
          multi=true,
        );

      local cpu =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          format='core',
          min=0,
          stack=true,
          linewidth=2,
          fill=2,
        )
        .addSeriesOverride({ alias: '/PodRequests/', color: $._config.dashboardCommon.color.red, dashes: true, fill: 0, legend: true, linewidth: 2, stack: false })
        .addSeriesOverride({ alias: '/PodLimits/', color: $._config.dashboardCommon.color.orange, dashes: true, fill: 0, legend: true, linewidth: 2, stack: false })
        .addTargets(
          [
            prometheus.target('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", container=~"$container"}) by ($view)', legendFormat='{{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_requests_cpu_cores{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodRequests - {{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_limits_cpu_cores{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodLimits - {{$view}}'),
          ],
        );

      local memory =
        graphPanel.new(
          title='Memory Usage',
          datasource='$datasource',
          format='bytes',
          min=0,
          stack=true,
          linewidth=2,
          fill=2,
        )
        .addSeriesOverride({ alias: '/PodRequests/', dashes: true, fill: 0, legend: true, linewidth: 2, stack: false })
        .addSeriesOverride({ alias: '/PodLimits/', dashes: true, fill: 0, legend: true, linewidth: 2, stack: false })
        .addTargets(
          [
            prometheus.target('sum(container_memory_working_set_bytes{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", id!="", container!="POD", container=~"$container"}) by ($view)', legendFormat='{{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_requests_memory_bytes{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodRequests - {{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_limits_memory_bytes{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodLimits - {{$view}}'),
          ],
        );

      local bandwidth =
        graphPanel.new(
          title='Transmit/Receive Bandwidth',
          datasource='$datasource',
          format='Bps',
          stack=true,
          linewidth=2,
          fill=2,
        )
        .addSeriesOverride({ alias: '/Rx_/', stack: 'B', transform: 'negative-Y' })
        .addSeriesOverride({ alias: '/Tx_/', stack: 'A' })
        .addTargets(
          [
            prometheus.target('sum(irate(container_network_transmit_bytes_total{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Tx_{{pod}}'),
            prometheus.target('sum(irate(container_network_receive_bytes_total{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Rx_{{pod}}'),
          ],
        );

      local drops =
        graphPanel.new(
          title='Transmit/Receive Drops',
          datasource='$datasource',
          format='pps',
          stack=true,
          linewidth=2,
          fill=2,
        )
        .addSeriesOverride({ alias: '/Rx_/', stack: 'B', transform: 'negative-Y' })
        .addSeriesOverride({ alias: '/Tx_/', stack: 'A' })
        .addTargets(
          [
            prometheus.target('sum(irate(container_network_transmit_packets_dropped_total{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Tx_{{pod}}'),
            prometheus.target('sum(irate(container_network_receive_packets_dropped_total{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Rx_{{pod}}'),
          ],
        );

      local count =
        graphPanel.new(
          title='Count (avg for 10s intervals)',
          datasource='$datasource_logs',
          format='logs',
          min=0,
          stack=true,
          legend_alignAsTable=true,
          legend_current=true,
          legend_rightSide=true,
        )
        .addSeriesOverride({ alias: 'Value #A', legend: false, hiddenSeries: true })
        .addTarget(loki.target('sum(count_over_time({cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"[10s])) by ($view)', legendFormat='{{$view}}'));

      local logs =
        logPanel.new(
          title='Logs',
          datasource='$datasource_logs',
          showLabels=true,
        )
        .addTarget(loki.target('{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"'));

      local rate =
        graphPanel.new(
          title='Rate',
          datasource='$datasource',
          format='ops',
          linewidth=2,
          fill=2,
          min=0,
          legend_current=true,
          legend_values=true,
        )
        .addTarget(
          prometheus.target('sum(rate(http_server_requests_seconds_count{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod"}[1m]))',
                            legendFormat='HTTP'),
        );

      local successRate =
        graphPanel.new(
          title='Success Rate (non-4|5xx responses)',
          datasource='$datasource',
          format='ops',
          linewidth=2,
          fill=2,
          min=0,
          legend_current=true,
          legend_values=true,
        )
        .addTarget(
          prometheus.target('sum(rate(http_server_requests_seconds_count{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", status=~"[4-5].*"}[1m]))',
                            legendFormat='HTTP - 5xx|4xx'),
        );

      local duration =
        graphPanel.new(
          title='Duration',
          datasource='$datasource',
          format='s',
          linewidth=2,
          fill=2,
          min=0,
          legend_current=true,
          legend_values=true,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(http_server_requests_seconds_sum{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", status!~"5.."}[1m]))/sum(rate(http_server_requests_seconds_count{job=~"$job", namespace=~"$namespace", pod=~"$pod", status!~"5.."}[1m]))', legendFormat='HTTP - AVG'),
            prometheus.target('max(http_server_requests_seconds_max{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", status!~"5.."})', legendFormat='HTTP - MAX'),
          ],
        );

      local heapUsed =
        statPanel.new(
          title='Heap used',
          datasource='$datasource',
          unit='percent',
          decimals=2,
        )
        .addThresholds($.grafanaThresholds($._config.thresholds.node))
        .addTarget(
          prometheus.target('sum(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="heap"})*100/sum(jvm_memory_max_bytes{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="heap"})'),
        );

      local NonHeapUsed =
        statPanel.new(
          title='Non-Heap used',
          datasource='$datasource',
          unit='percent',
          decimals=2,
        )
        .addThresholds($.grafanaThresholds($._config.thresholds.node))
        .addTarget(
          prometheus.target('sum(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="nonheap"})*100/sum(jvm_memory_max_bytes{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="nonheap"})'),
        );

      local JvmHeap =
        graphPanel.new(
          title='JVM Heap',
          datasource='$datasource',
          format='bytes',
          linewidth=2,
          fill=2,
          min=0,
          legend_max=true,
          legend_current=true,
          legend_values=true,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="heap"}) by ($view)', legendFormat='used - {{$view}}'),
            prometheus.target('sum(jvm_memory_committed_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="heap"}) by ($view)', legendFormat='committed - {{$view}}'),
            prometheus.target('sum(jvm_memory_max_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="heap"}) by ($view)', legendFormat='max - {{$view}}'),
          ],
        );

      local JvmNonHeap =
        graphPanel.new(
          title='JVM Non-Heap',
          datasource='$datasource',
          format='bytes',
          linewidth=2,
          fill=2,
          min=0,
          legend_max=true,
          legend_current=true,
          legend_values=true,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="nonheap"}) by ($view)', legendFormat='used - {{$view}}'),
            prometheus.target('sum(jvm_memory_committed_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="nonheap"}) by ($view)', legendFormat='committed - {{$view}}'),
            prometheus.target('sum(jvm_memory_max_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", area="nonheap"}) by ($view)', legendFormat='max - {{$view}}'),
          ],
        );

      local total =
        graphPanel.new(
          title='JVM Total',
          datasource='$datasource',
          format='bytes',
          linewidth=2,
          fill=2,
          legend_max=true,
          legend_current=true,
          legend_values=true,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='used - {{$view}}'),
            prometheus.target('sum(jvm_memory_committed_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='committed - {{$view}}'),
            prometheus.target('sum(jvm_memory_max_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='max - {{$view}}'),
            prometheus.target('sum(process_memory_vss_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='vss - {{$view}}'),
            prometheus.target('sum(process_memory_rss_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='rss - {{$view}}'),
            prometheus.target('sum(process_memory_pss_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='pss - {{$view}}'),
            prometheus.target('sum(process_memory_swap_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='swap - {{$view}}'),
            prometheus.target('sum(process_memory_swappss_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='swappss - {{$view}}'),
            prometheus.target('sum(process_memory_pss_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) + sum(process_memory_swap_bytes{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='phys (pss+swap) - {{$view}}'),
          ],
        );

      local threads =
        graphPanel.new(
          title='Threads',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
          legend_current=true,
          legend_values=true,
          legend_max=true,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_threads_live{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) or sum(jvm_threads_live_threads{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) ', legendFormat='live - {{$view}}'),
            prometheus.target('sum(jvm_threads_daemon{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"})  by ($view)  or sum(jvm_threads_daemon_threads{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='daemon - {{$view}}'),
            prometheus.target('sum(jvm_threads_peak{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"})  by ($view)  or sum(jvm_threads_peak_threads{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='peak - {{$view}}'),
            prometheus.target('sum(process_threads{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"})  by ($view)', legendFormat='process - {{$view}}'),
          ],
        );

      local threadsStates =
        graphPanel.new(
          title='Thread States',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          legend_current=true,
          legend_values=true,
          legend_max=true,
        )
        .addSeriesOverride({ alias: '/blocked/', color: $._config.dashboardCommon.color.red })
        .addSeriesOverride({ alias: '/waiting/', color: $._config.dashboardCommon.color.yellow })
        .addSeriesOverride({ alias: '/new/', color: $._config.dashboardCommon.color.pink })
        .addSeriesOverride({ alias: '/runnable/', color: $._config.dashboardCommon.color.green })
        .addSeriesOverride({ alias: '/terminated/', color: $._config.dashboardCommon.color.purple })
        .addSeriesOverride({ alias: '/timed-waiting/', color: $._config.dashboardCommon.color.orange })
        .addTarget(
          prometheus.target('sum(jvm_threads_states_threads{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"})  by (state, $view)', legendFormat='{{state}} - {{$view}}'),
        );

      local fileDescriptions =
        graphPanel.new(
          title='File Descriptors',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
          logBase1Y=10,
          legend_current=true,
          legend_values=true,
          legend_max=true,
        )
        .addTargets(
          [
            prometheus.target('sum(process_open_fds{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='open - {{$view}}'),
            prometheus.target('sum(process_max_fds{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='max - {{$view}}'),
            prometheus.target('sum(process_files_open{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) or sum(process_files_open_files{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='open - {{$view}}'),
            prometheus.target('sum(process_files_max{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) or sum(process_files_max_files{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='max - {{$view}}'),
          ],
        );

      local logEvents =
        graphPanel.new(
          title='Log Events (1m)',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
          legend_current=true,
          legend_values=true,
          legend_max=true,
        )
        .addSeriesOverride({ alias: '/error/', color: $._config.dashboardCommon.color.red, yaxis: 1 })
        .addSeriesOverride({ alias: '/warn/', color: $._config.dashboardCommon.color.yellow, yaxis: 1 })
        .addSeriesOverride({ alias: '/trace/', color: $._config.dashboardCommon.color.lightblue })
        .addSeriesOverride({ alias: '/info/', color: $._config.dashboardCommon.color.green })
        .addSeriesOverride({ alias: '/debug/', color: $._config.dashboardCommon.color.blue })
        .addTarget(
          prometheus.target('sum(increase(logback_events_total{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by (level, $view)', legendFormat='{{level}} - {{$view}}'),
        );

      local edenSpace =
        graphPanel.new(
          title='$jvm_memory_pool_heap',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
          format='bytes',
          repeat='jvm_memory_pool_heap',
          legend_current=true,
          legend_max=true,
          legend_values=true,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="$jvm_memory_pool_heap"}) by ($view)', legendFormat='used - {{$view}}'),
            prometheus.target('sum(jvm_memory_committed_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="$jvm_memory_pool_heap"}) by ($view)', legendFormat='commited - {{$view}}'),
            prometheus.target('sum(jvm_memory_max_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="$jvm_memory_pool_heap"}) by ($view)', legendFormat='max - {{$view}}'),
          ],
        );

      local jvmMemoryPoolNonHeap =
        graphPanel.new(
          title='$jvm_memory_pool_nonheap',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
          format='bytes',
          repeat='jvm_memory_pool_nonheap',
          legend_current=true,
          legend_max=true,
          legend_values=true,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="${jvm_memory_pool_nonheap:raw}"}) by ($view)', legendFormat='used - {{$view}}'),
            prometheus.target('sum(jvm_memory_committed_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="${jvm_memory_pool_nonheap:raw}"}) by ($view)', legendFormat='commited - {{$view}}'),
            prometheus.target('sum(jvm_memory_max_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="${jvm_memory_pool_nonheap:raw}"}) by ($view)', legendFormat='max - {{$view}}'),
          ],
        );

      local collections =
        graphPanel.new(
          title='Collections',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
          format='ops',
        )
        .addTarget(
          prometheus.target('sum(rate(jvm_gc_pause_seconds_count{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by (action, cause, $view)', legendFormat='{{action}} ({{cause}}) - {{$view}}'),
        );

      local pauseDurations =
        graphPanel.new(
          title='Pause Durations',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
          format='s',
        )
        .addTargets(
          [
            prometheus.target('sum(rate(jvm_gc_pause_seconds_sum{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by (action, cause, $view) /sum(rate(jvm_gc_pause_seconds_count{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by (action, cause, $view)', legendFormat='avg {{action}} ({{cause}}) - {{$view}}'),
            prometheus.target('sum(jvm_gc_pause_seconds_max{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by (action, cause, $view)', legendFormat='max {{action}} ({{cause}}) - {{$view}}'),
          ],
        );

      local allocatedPromoted =
        graphPanel.new(
          title='Allocated/Promoted',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
          format='bytes',
        )
        .addTargets(
          [
            prometheus.target('sum(rate(jvm_gc_memory_allocated_bytes_total{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by ($view)', legendFormat='allocated - {{$view}}'),
            prometheus.target('sum(rate(jvm_gc_memory_promoted_bytes_total{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m])) by ($view)', legendFormat='promoted - {{$view}}'),
          ],
        );

      local classesLoaded =
        graphPanel.new(
          title='Classes loaded',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
        )
        .addTarget(
          prometheus.target('sum(jvm_classes_loaded{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view) or sum(jvm_classes_loaded_classes{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='loaded - {{$view}}'),
        );

      local classDelta =
        graphPanel.new(
          title='Class delta (5m)',
          datasource='$datasource',
          linewidth=2,
          fill=2,
        )
        .addTarget(
          prometheus.target('sum(delta(jvm_classes_loaded{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[5m])) by ($view) or sum(delta(jvm_classes_loaded_classes{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[5m])) by ($view)', legendFormat='delta - {{$view}}'),
        );

      local directBuffersMemoryUsedBytes =
        graphPanel.new(
          title='Direct Buffers (Memory Used Bytes)',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
          format='bytes',
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_buffer_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="direct"}) by ($view)', legendFormat='used - {{$view}}'),
            prometheus.target('sum(jvm_buffer_total_capacity_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="direct"}) by ($view)', legendFormat='capacity - {{$view}}'),
          ],
        );

      local directBuffersCount =
        graphPanel.new(
          title='Direct Buffers (Count)',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_buffer_count{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="direct"}) by ($view) or sum(jvm_buffer_count_buffers{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="direct"}) by ($view)', legendFormat='count - {{$view}}'),
          ],
        );

      local mappedBuffersMemoryUsedBytes =
        graphPanel.new(
          title='Mapped Buffers (Memory Used Bytes)',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          format='bytes',
          min=0,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_buffer_memory_used_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="mapped"}) by ($view)', legendFormat='used - {{$view}}'),
            prometheus.target('sum(jvm_buffer_total_capacity_bytes{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="mapped"}) by ($view)', legendFormat='capacity - {{$view}}'),
          ],
        );

      local mappedBuffersCount =
        graphPanel.new(
          title='Mapped Buffers (Count)',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          min=0,
        )
        .addTargets(
          [
            prometheus.target('sum(jvm_buffer_count{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="mapped"}) by ($view) or sum(jvm_buffer_count_buffers{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", id="mapped"}) by ($view)', legendFormat='count - {{$view}}'),
          ],
        );

      local templates = [
                          datasourceTemplate,
                        ]
                        + (if $._config.isLoki then [datasourceLogsTemplate] else [])
                        + [
                          clusterTemplate,
                          jobTemplate,
                          viewByTemplate,
                          namespaceTemplate,
                          podTemplate,
                          containerTemplate,
                          memoryPoolsHeap,
                          memoryPoolsNonHeap,
                        ]
                        + if $._config.isLoki then [searchTemplate] else [];

      local logsPanels = [
        row.new('Logs', collapse=true) { gridPos: { x: 0, y: 5, w: 24, h: 1 } }
        .addPanel(count { tooltip+: { sort: 2 } }, { x: 0, y: 6, w: 24, h: 5 })
        .addPanel(logs, { x: 0, y: 11, w: 24, h: 13 }),
      ];

      local panels = [
        row.new('CPU Usage', collapse=true) { gridPos: { x: 0, y: 0, w: 24, h: 1 } }
        .addPanel(cpu { tooltip+: { sort: 2 } }, { x: 0, y: 1, w: 24, h: 7 }),
        row.new('Memory Usage', collapse=true) { gridPos: { x: 0, y: 1, w: 24, h: 1 } }
        .addPanel(memory { tooltip+: { sort: 2 } }, { x: 0, y: 2, w: 24, h: 7 }),
        row.new('Network Bandwidth', collapse=true) { gridPos: { x: 0, y: 2, w: 24, h: 1 } }
        .addPanel(bandwidth { tooltip+: { sort: 2 } }, { x: 0, y: 3, w: 24, h: 7 }),
        row.new('Network Rate', collapse=true) { gridPos: { x: 0, y: 3, w: 24, h: 1 } }
        .addPanel(rate { tooltip+: { sort: 2 } }, { x: 0, y: 4, w: 8, h: 7 })
        .addPanel(successRate { tooltip+: { sort: 2 } }, { x: 8, y: 4, w: 8, h: 7 })
        .addPanel(duration { tooltip+: { sort: 2 } }, { x: 16, y: 4, w: 8, h: 7 }),
        row.new('Network Drops', collapse=true) { gridPos: { x: 0, y: 4, w: 24, h: 1 } }
        .addPanel(drops { tooltip+: { sort: 2 } }, { x: 0, y: 5, w: 24, h: 7 }),
        row.new('Overview') { gridPos: { x: 0, y: 6, w: 24, h: 1 } },
        heapUsed { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 7, w: 12, h: 3 } },
        NonHeapUsed { tooltip+: { sort: 2 }, gridPos: { x: 12, y: 7, w: 12, h: 3 } },
        row.new('JVM Memory') { gridPos: { x: 0, y: 10, w: 24, h: 1 } },
        JvmHeap { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 11, w: 8, h: 7 } },
        JvmNonHeap { tooltip+: { sort: 2 }, gridPos: { x: 8, y: 11, w: 8, h: 7 } },
        total { tooltip+: { sort: 2 }, gridPos: { x: 16, y: 11, w: 8, h: 7 } },
        row.new('JVM Misc', collapse=true) { gridPos: { x: 0, y: 18, w: 24, h: 1 } }
        .addPanel(threads { tooltip+: { sort: 2 } }, { x: 0, y: 19, w: 8, h: 8 })
        .addPanel(threadsStates { tooltip+: { sort: 2 } }, { x: 8, y: 19, w: 8, h: 8 })
        .addPanel(fileDescriptions { tooltip+: { sort: 2 } }, { x: 16, y: 19, w: 8, h: 8 })
        .addPanel(logEvents { tooltip+: { sort: 2 } }, { x: 0, y: 27, w: 24, h: 7 }),
        row.new('JVM Memory Pools(Heap)', collapse=true) { gridPos: { x: 0, y: 19, w: 24, h: 1 } }
        .addPanel(edenSpace { tooltip+: { sort: 2 } }, { x: 0, y: 20, w: 8, h: 7 }),
        row.new('JVM Memory Pools(Non-Heap)', collapse=true) { gridPos: { x: 0, y: 20, w: 24, h: 1 } }
        .addPanel(jvmMemoryPoolNonHeap { maxPerRow: 3, tooltip+: { sort: 2 } }, { x: 0, y: 21, w: 8, h: 7 }),
        row.new('Garbage Collection', collapse=true) { gridPos: { x: 0, y: 21, w: 24, h: 1 } }
        .addPanel(collections { tooltip+: { sort: 2 } }, { x: 0, y: 22, w: 8, h: 7 })
        .addPanel(pauseDurations { tooltip+: { sort: 2 } }, { x: 8, y: 22, w: 8, h: 7 })
        .addPanel(allocatedPromoted { tooltip+: { sort: 2 } }, { x: 16, y: 22, w: 8, h: 7 }),
        row.new('Classloading', collapse=true) { gridPos: { x: 0, y: 22, w: 24, h: 1 } }
        .addPanel(classesLoaded { tooltip+: { sort: 2 } }, { x: 0, y: 23, w: 12, h: 7 })
        .addPanel(classDelta { tooltip+: { sort: 2 } }, { x: 12, y: 23, w: 12, h: 7 }),
        row.new('Buffer Pools', collapse=true) { gridPos: { x: 0, y: 23, w: 24, h: 1 } }
        .addPanel(directBuffersMemoryUsedBytes { tooltip+: { sort: 2 } }, { x: 0, y: 24, w: 6, h: 7 })
        .addPanel(directBuffersCount { tooltip+: { sort: 2 } }, { x: 6, y: 24, w: 6, h: 7 })
        .addPanel(mappedBuffersMemoryUsedBytes { tooltip+: { sort: 2 } }, { x: 12, y: 24, w: 6, h: 7 })
        .addPanel(mappedBuffersCount { tooltip+: { sort: 2 } }, { x: 18, y: 24, w: 6, h: 7 }),
      ] + if $._config.isLoki then logsPanels else [];

      dashboard.new(
        'Java Actuator',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sApps,
        uid=$._config.dashboardIDs.javaActuator,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
