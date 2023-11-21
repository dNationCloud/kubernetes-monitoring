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

/* K8s python flask dashboard */
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local loki = grafana.loki;
local graphPanel = grafana.graphPanel;
local logPanel = grafana.logPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    'python-flask':
      local cpu =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          format='core',
          min=0,
          stack=true,
          nullPointMode='null as zero',
          linewidth=2,
          fill=2,
        )
        .addSeriesOverride({ alias: '/PodRequests/', color: $._config.grafanaDashboards.color.red, dashes: true, fill: 0, stack: false, hideTooltip: true })
        .addSeriesOverride({ alias: '/PodLimits/', color: $._config.grafanaDashboards.color.orange, dashes: true, fill: 0, stack: false, hideTooltip: true })
        .addTargets(
          [
            prometheus.target('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", container=~"$container"}) by ($view)', legendFormat='{{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_requests{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodRequests - {{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_limits{resource="cpu", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodLimits - {{$view}}'),
          ],
        );

      local memory =
        graphPanel.new(
          title='Memory Usage',
          datasource='$datasource',
          format='bytes',
          min=0,
          stack=true,
          nullPointMode='null as zero',
          linewidth=2,
          fill=2,
        )
        .addSeriesOverride({ alias: '/PodRequests/', color: $._config.grafanaDashboards.color.red, dashes: true, fill: 0, stack: false, hideTooltip: true })
        .addSeriesOverride({ alias: '/PodLimits/', color: $._config.grafanaDashboards.color.orange, dashes: true, fill: 0, stack: false, hideTooltip: true })
        .addTargets(
          [
            prometheus.target('sum(container_memory_working_set_bytes{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", id!="", container!="POD", container=~"$container"}) by ($view)', legendFormat='{{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_requests{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodRequests - {{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_limits{resource="memory", cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodLimits - {{$view}}'),
          ],
        );

      local bandwidth =
        graphPanel.new(
          title='Transmit/Receive Bandwidth',
          datasource='$datasource',
          format='Bps',
          stack=true,
          nullPointMode='null as zero',
          linewidth=2,
          fill=2,
        )
        .addSeriesOverride({ alias: '/Rx_/', stack: 'B', transform: 'negative-Y' })
        .addSeriesOverride({ alias: '/Tx_/', stack: 'A' })
        .addTargets(
          [
            prometheus.target('sum(irate(container_network_transmit_bytes_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Tx_{{pod}}'),
            prometheus.target('sum(irate(container_network_receive_bytes_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Rx_{{pod}}'),
          ],
        );

      local drops =
        graphPanel.new(
          title='Transmit/Receive Drops',
          datasource='$datasource',
          format='pps',
          stack=true,
          nullPointMode='null as zero',
          linewidth=2,
          fill=2,
        )
        .addSeriesOverride({ alias: '/Rx_/', stack: 'B', transform: 'negative-Y' })
        .addSeriesOverride({ alias: '/Tx_/', stack: 'A' })
        .addTargets(
          [
            prometheus.target('sum(irate(container_network_transmit_packets_dropped_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Tx_{{pod}}'),
            prometheus.target('sum(irate(container_network_receive_packets_dropped_total{cluster="$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Rx_{{pod}}'),
          ],
        );

      local count =
        graphPanel.new(
          title='Count (avg for 10s intervals)',
          datasource='$datasource_logs',
          format='logs',
          min=0,
          stack=true,
          nullPointMode='null as zero',
          legend_alignAsTable=true,
          legend_current=true,
          legend_rightSide=true,
          legend_sort='current',
          legend_sortDesc=true,
          legend_values=true,
        )
        .addSeriesOverride({ alias: 'Value #A', legend: false, hiddenSeries: true })
        .addTarget(loki.target('sum(count_over_time({cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"[10s])) by ($view)', legendFormat='{{$view}}'));

      local logs =
        logPanel.new(
          title='Logs',
          datasource='$datasource_logs',
          showLabels=true,
        )
        .addTarget(loki.target('{cluster="$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"'));

      local requestPerMinute =
        graphPanel.new(
          title='Total requests per minute',
          datasource='$datasource',
          stack=true,
          nullPointMode='null as zero',
          linewidth=2,
          fill=2,
          legend_alignAsTable=true,
          legend_current=true,
          legend_rightSide=true,
          legend_max=true,
          legend_values=true,
        )
        .addSeriesOverride({ alias: 'HTTP 500', color: $._config.grafanaDashboards.color.red })
        .addTarget(
          prometheus.target(
            'sum(increase(\n  flask_http_request_total{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container"}[1m]\n) / 2) by (status, $view)',
            legendFormat='HTTP {{status}} - {{$view}}',
          ),
        );

      local errorsPerMinute =
        graphPanel.new(
          title='Errors per minute',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          legend_alignAsTable=true,
          legend_current=true,
          legend_rightSide=true,
          legend_max=true,
          legend_values=true,
        )
        .addSeriesOverride({ alias: 'errors', color: $._config.grafanaDashboards.color.orange })
        .addTarget(
          prometheus.target(
            'sum(\n  rate(\n    flask_http_request_duration_seconds_count{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status!="200"}[1m]\n)\n) by (status, $view)',
            legendFormat='HTTP {{status}} - {{$view}}',
          ),
        );

      local averageResponseTime =
        graphPanel.new(
          title='Average response time [1m]',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          format='s',
          legend_avg=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
          legend_max=true,
          legend_min=true,
          legend_values=true,
          legend_sort='avg',
          legend_sortDesc=true,
        )
        .addTarget(prometheus.target('avg(rate(\n  flask_http_request_duration_seconds_sum{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200"}[1m]\n)\n /\nrate(\n  flask_http_request_duration_seconds_count{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200"}[1m]\n) >= 0)  by (status, $view)', legendFormat='HTTP 200 - {{$view}}'));

      local requestUnder =
        graphPanel.new(
          title='Requests under 250ms',
          datasource='$datasource',
          linewidth=2,
          fill=2,
          format='none',
          legend_avg=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
          legend_max=true,
          legend_min=true,
          legend_values=true,
          legend_sort='avg',
          legend_sortDesc=true,
        )
        .addTarget(prometheus.target('sum(increase(\n  flask_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200",le="0.25"}[1m]\n)\n / ignoring (le)\nincrease(\n  flask_http_request_duration_seconds_count{job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200"}[1m]\n) >= 0) by (status, $view)', legendFormat='HTTP 200 - {{$view}}'));

      local requestDurationP50 =
        graphPanel.new(
          title='Request duration [s] - p50',
          datasource='$datasource',
          description='The 50th percentile of request durations over the last 60 seconds. In other words, half of the requests finish in (min/max/avg) these times.',
          linewidth=2,
          fill=2,
          legend_avg=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
          legend_max=true,
          legend_min=true,
          legend_values=true,
          legend_sort='avg',
          legend_sortDesc=true,
        )
        .addTarget(prometheus.target('avg(histogram_quantile(\n  0.5,\n  rate(\n    flask_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200"}[1m]\n  )\n)>=0) by (status, $view)', legendFormat='HTTP 200 - {{$view}}'));

      local requestDurationP90 =
        graphPanel.new(
          title='Request duration [s] - p90',
          datasource='$datasource',
          description='The 90th percentile of request durations over the last 60 seconds. In other words, 90 percent of the requests finish in (min/max/avg) these times.',
          linewidth=2,
          fill=2,
          legend_avg=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
          legend_max=true,
          legend_min=true,
          legend_values=true,
          legend_sort='avg',
          legend_sortDesc=true,
        )
        .addTarget(prometheus.target('avg(histogram_quantile(\n  0.9,\n  rate(\n    flask_http_request_duration_seconds_bucket{cluster="$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", container=~"$container", status="200"}[1m]\n  )\n)>=0) by (status, $view)', legendFormat='HTTP 200 - {{$view}}'));

      local templates =
        [
          $.grafanaTemplates.datasourceTemplate(),
        ]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.datasourceLogsTemplate()] else [])
        + [
          $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
          $.grafanaTemplates.jobTemplate('label_values(flask_exporter_info{cluster="$cluster"}, job)'),
          $.grafanaTemplates.viewByTemplate('pod,container'),
          $.grafanaTemplates.namespaceTemplate('label_values(flask_exporter_info{cluster="$cluster", job=~"$job"}, namespace)'),
          $.grafanaTemplates.podTemplate('label_values(flask_exporter_info{cluster="$cluster", job=~"$job", namespace=~"$namespace"}, pod)'),
          $.grafanaTemplates.containerTemplate('label_values(flask_exporter_info{cluster="$cluster", job=~"$job", namespace=~"$namespace"}, container)'),
        ]
        + if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.searchTemplate()] else [];

      local logsPanels = [
        row.new('Logs', collapse=true) { gridPos: { x: 0, y: 4, w: 24, h: 1 } }
        .addPanel(count { tooltip+: { sort: 2 } }, { x: 0, y: 5, w: 24, h: 5 })
        .addPanel(logs, { x: 0, y: 10, w: 24, h: 13 }),
      ];

      local panels = [
        row.new('CPU Usage', collapse=true) { gridPos: { x: 0, y: 0, w: 24, h: 1 } }
        .addPanel(cpu { tooltip+: { sort: 2 } }, { x: 0, y: 1, w: 24, h: 7 }),
        row.new('Memory Usage', collapse=true) { gridPos: { x: 0, y: 1, w: 24, h: 1 } }
        .addPanel(memory { tooltip+: { sort: 2 } }, { x: 0, y: 2, w: 24, h: 7 }),
        row.new('Network Bandwidth', collapse=true) { gridPos: { x: 0, y: 2, w: 24, h: 1 } }
        .addPanel(bandwidth { tooltip+: { sort: 2 } }, { x: 0, y: 3, w: 24, h: 7 }),
        row.new('Network Drops', collapse=true) { gridPos: { x: 0, y: 3, w: 24, h: 1 } }
        .addPanel(drops { tooltip+: { sort: 2 } }, { x: 0, y: 4, w: 24, h: 7 }),
        row.new('Server') { gridPos: { x: 0, y: 5, w: 24, h: 1 } },
        requestPerMinute { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 6, w: 12, h: 7 } },
        errorsPerMinute { tooltip+: { sort: 2 }, gridPos: { x: 12, y: 6, w: 12, h: 7 } },
        averageResponseTime { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 13, w: 12, h: 7 } },
        requestUnder { tooltip+: { sort: 2 }, gridPos: { x: 12, y: 13, w: 12, h: 7 } },
        requestDurationP50 { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 20, w: 12, h: 7 } },
        requestDurationP90 { tooltip+: { sort: 2 }, gridPos: { x: 12, y: 20, w: 12, h: 7 } },
      ] + if $._config.grafanaDashboards.isLoki then logsPanels else [];

      dashboard.new(
        'Python Flask',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.pythonFlask,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
