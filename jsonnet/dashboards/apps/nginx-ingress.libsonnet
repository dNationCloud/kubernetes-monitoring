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

/* K8s nginx ingress dashboard */
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local template = grafana.template;
local prometheus = grafana.prometheus;
local loki = grafana.loki;
local graphPanel = grafana.graphPanel;
local logPanel = grafana.logPanel;
local statPanel = grafana.statPanel;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'nginx-ingress':
      local ingressTemplate =
        template.new(
          name='ingress',
          label='Ingress',
          datasource='$datasource',
          query='label_values(nginx_ingress_controller_requests{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod"}, ingress)',
          refresh=$._config.grafanaDashboards.templateRefresh,
          sort=$._config.grafanaDashboards.templateSort,
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
          nullPointMode='null as zero',
          linewidth=2,
          fill=2,
        )
        .addSeriesOverride({ alias: '/PodRequests/', color: $._config.grafanaDashboards.color.red, dashes: true, fill: 0, stack: false, hideTooltip: true })
        .addSeriesOverride({ alias: '/PodLimits/', color: $._config.grafanaDashboards.color.orange, dashes: true, fill: 0, stack: false, hideTooltip: true })
        .addTargets(
          [
            prometheus.target('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", container=~"$container"}) by ($view)', legendFormat='{{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_requests{resource="cpu", cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodRequests - {{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_limits{resource="cpu", cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodLimits - {{$view}}'),
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
            prometheus.target('sum(container_memory_working_set_bytes{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", id!="", container!="POD", container=~"$container"}) by ($view)', legendFormat='{{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_requests{resource="memory", cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodRequests - {{$view}}'),
            prometheus.target('sum(\nkube_pod_container_resource_limits{resource="memory", cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)\n', legendFormat='PodLimits - {{$view}}'),
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
          nullPointMode='null as zero',
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
          nullPointMode='null as zero',
          legend_alignAsTable=true,
          legend_current=true,
          legend_rightSide=true,
          legend_sort='current',
          legend_sortDesc=true,
          legend_values=true,
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

      local controllerRequestVolume =
        statPanel.new(
          title='Controller Request Volume',
          datasource='$datasource',
          unit='reqps',
        )
        .addTarget(prometheus.target('round(sum(irate(nginx_ingress_controller_requests{cluster=~"$cluster", job=~"$job", controller_pod=~"$pod", namespace=~"$namespace", container=~"$container"}[5m])), 0.001)'));

      local configReloads =
        statPanel.new(
          title='Config Reloads',
          datasource='$datasource',
          decimals=0,
        )
        .addTarget(prometheus.target('avg(nginx_ingress_controller_success{cluster=~"$cluster", job=~"$job", controller_pod=~"$pod", controller_namespace=~"$namespace", container=~"$container"})'));

      local ingressRequestVolume =
        graphPanel.new(
          title='Ingress Request Volume',
          datasource='$datasource',
          format='reqps',
          decimals=2,
          linewidth=2,
          legend_alignAsTable=true,
          legend_rightSide=true,
          legend_sort='avg',
          legend_sortDesc=true,
          legend_hideZero=true,
          legend_avg=true,
          legend_values=true,
        )
        .addTarget(prometheus.target('round(sum(irate(nginx_ingress_controller_requests{cluster=~"$cluster", job=~"$job", controller_pod=~"$pod", controller_namespace=~"$namespace", ingress=~"$ingress", container=~"$container"}[5m])) by (ingress), 0.001)', legendFormat='{{ingress}}'));

      local controllerConnections =
        statPanel.new(
          title='Controller Connections',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('sum(avg_over_time(nginx_ingress_controller_nginx_process_connections{cluster=~"$cluster", job=~"$job", controller_pod=~"$pod", controller_namespace=~"$namespace", container=~"$container"}[5m]))'));

      local configFailed =
        statPanel.new(
          title='Last Config Failed',
          datasource='$datasource',
          noValue='0',
        )
        .addTarget(prometheus.target('count(nginx_ingress_controller_config_last_reload_successful{cluster=~"$cluster", job=~"$job", controller_pod=~"$pod",controller_namespace=~"$namespace", container=~"$container"} == 0)'));

      local controllerSuccessRate =
        statPanel.new(
          title='Controller Success Rate (non-4|5xx responses)',
          datasource='$datasource',
          colorMode='background',
          unit='percent',
        )
        .addThresholds(
          [
            { color: $._config.grafanaDashboards.color.red, value: null },
            { color: $._config.grafanaDashboards.color.orange, value: 75 },
            { color: $._config.grafanaDashboards.color.green, value: 90 },
          ]
        )
        .addTarget(prometheus.target('sum(rate(nginx_ingress_controller_requests{cluster=~"$cluster", job=~"$job", controller_pod=~"$pod",namespace=~"$namespace",status!~"[4-5].*", container=~"$container"}[5m])) / sum(rate(nginx_ingress_controller_requests{cluster=~"$cluster", job=~"$job", controller_pod=~"$pod", namespace=~"$namespace", container=~"$container"}[5m])) * 100'));

      local ingressSuccessRate =
        graphPanel.new(
          title='Ingress Success Rate (non-4|5xx responses)',
          datasource='$datasource',
          format='percentunit',
          decimals=2,
          legend_alignAsTable=true,
          legend_rightSide=true,
          legend_sort='current',
          legend_sortDesc=true,
          legend_hideEmpty=true,
          legend_avg=true,
          legend_current=true,
          legend_max=true,
          legend_min=true,
          legend_values=true,
        )
        .addTarget(prometheus.target('sum(rate(nginx_ingress_controller_requests{cluster=~"$cluster", job=~"$job", controller_pod=~"$pod",namespace=~"$namespace",ingress=~"$ingress",status!~"[4-5].*",  container=~"$container"}[5m])) by (ingress) / sum(rate(nginx_ingress_controller_requests{cluster=~"$cluster", job=~"$job", controller_pod=~"$pod",namespace=~"$namespace",  container=~"$container", ingress=~"$ingress"}[5m])) by (ingress)', legendFormat='{{ingress}}'));

      local percentileTable =
        table.new(
          title='Ingress Percentile Response Times and Transfer Rates',
          datasource='$datasource',
          sort={ col: 1, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Ingress', pattern: 'ingress', type: 'string' },
            { alias: 'P50 Latency', pattern: 'Value #A', type: 'number', unit: 'dtdurations', decimals: 0 },
            { alias: 'P90 Latency', pattern: 'Value #B', type: 'number', unit: 'dtdurations', decimals: 0 },
            { alias: 'P99 Latency', pattern: 'Value #C', type: 'number', unit: 'dtdurations', decimals: 0 },
            { alias: 'IN', pattern: 'Value #D', type: 'number', unit: 'Bps', decimals: 2 },
            { alias: 'OUT', pattern: 'Value #E', type: 'number', unit: 'Bps', decimals: 2 },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr='histogram_quantile(0.50, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{cluster=~"$cluster", job=~"$job", ingress!="", controller_pod=~"$pod",  container=~"$container", controller_namespace=~"$namespace", ingress=~"$ingress"}[5m])) by (le, ingress))'),
            prometheus.target(format='table', instant=true, expr='histogram_quantile(0.90, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{cluster=~"$cluster", job=~"$job", ingress!="", controller_pod=~"$pod",  container=~"$container", controller_namespace=~"$namespace", ingress=~"$ingress"}[5m])) by (le, ingress))'),
            prometheus.target(format='table', instant=true, expr='histogram_quantile(0.99, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{cluster=~"$cluster", job=~"$job", ingress!="", controller_pod=~"$pod",  container=~"$container", controller_namespace=~"$namespace", ingress=~"$ingress"}[5m])) by (le, ingress))'),
            prometheus.target(format='table', instant=true, expr='sum(irate(nginx_ingress_controller_request_size_sum{cluster=~"$cluster", job=~"$job", ingress!="", controller_pod=~"$pod",  container=~"$container", controller_namespace=~"$namespace", ingress=~"$ingress"}[5m])) by (ingress)'),
            prometheus.target(format='table', instant=true, expr='sum(irate(nginx_ingress_controller_response_size_sum{cluster=~"$cluster", job=~"$job", ingress!="", controller_pod=~"$pod",  container=~"$container", controller_namespace=~"$namespace", ingress=~"$ingress"}[5m])) by (ingress)'),
          ]
        );

      local colors = [$._config.grafanaDashboards.color.red, $._config.grafanaDashboards.color.orange, $._config.grafanaDashboards.color.green];

      local certificateTable =
        table.new(
          title='Ingress Certificate Expiry',
          datasource='$datasource',
          sort={ col: 2 },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Host', pattern: 'host', type: 'string' },
            { alias: 'TTL', pattern: 'Value', type: 'number', colors: colors, colorMode: 'cell', thresholds: [0, 8 * 24 * 60 * 60], unit: 's', decimals: 0 },
          ]
        )
        .addTarget(prometheus.target(format='table', instant=true, expr='avg(nginx_ingress_controller_ssl_expire_time_seconds{cluster=~"$cluster", job=~"$job", pod=~"$pod", namespace=~"$namespace", container=~"$container"}) by (host) - time()'));

      local templates =
        [
          $.grafanaTemplates.datasourceTemplate(),
        ]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.datasourceLogsTemplate()] else [])
        + [
          $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
          $.grafanaTemplates.jobTemplate('label_values(nginx_ingress_controller_config_hash{cluster=~"$cluster"}, job)'),
          $.grafanaTemplates.viewByTemplate('pod,container'),
          $.grafanaTemplates.namespaceTemplate('label_values(nginx_ingress_controller_config_hash{cluster=~"$cluster", job=~"$job"}, controller_namespace)'),
          $.grafanaTemplates.podTemplate('label_values(nginx_ingress_controller_config_hash{cluster=~"$cluster", job=~"$job", namespace=~"$namespace"}, pod)'),
          $.grafanaTemplates.containerTemplate('label_values(nginx_ingress_controller_config_hash{cluster=~"$cluster", job=~"$job", namespace=~"$namespace"}, container)'),
          ingressTemplate,
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
        row.new('Ingress overview') { gridPos: { x: 0, y: 5, w: 24, h: 1 } },
        controllerRequestVolume { gridPos: { x: 0, y: 6, w: 6, h: 3 } },
        configReloads { gridPos: { x: 6, y: 6, w: 6, h: 3 } },
        ingressRequestVolume { tooltip+: { sort: 2 }, gridPos: { x: 12, y: 6, w: 12, h: 6 } },
        controllerConnections { gridPos: { x: 0, y: 9, w: 6, h: 3 } },
        configFailed { gridPos: { x: 6, y: 9, w: 6, h: 3 } },
        controllerSuccessRate { gridPos: { x: 0, y: 12, w: 24, h: 3 } },
        ingressSuccessRate { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 15, w: 24, h: 9 } },
        row.new('Ingress Percentile Response Times and Transfer Rates', collapse=true) { gridPos: { x: 0, y: 24, w: 24, h: 1 } }
        .addPanel(percentileTable, { x: 0, y: 25, w: 24, h: 8 }),
        row.new('Ingress Certificate Expiry') { gridPos: { x: 0, y: 25, w: 24, h: 1 } },
        certificateTable { gridPos: { x: 6, y: 26, w: 24, h: 8 } },
      ] + if $._config.grafanaDashboards.isLoki then logsPanels else [];

      dashboard.new(
        'Nginx Ingress',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.nginxIngress,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
