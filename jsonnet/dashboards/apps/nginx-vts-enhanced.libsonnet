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

/* K8s nginx vts enhanced dashboard */
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local template = grafana.template;
local prometheus = grafana.prometheus;
local loki = grafana.loki;
local graphPanel = grafana.graphPanel;
local logPanel = grafana.logPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    'nginx-vts-enhanced':
      local hostTemplate =
        template.new(
          name='host',
          label='Host',
          datasource='$datasource',
          query='label_values(nginx_vts_server_bytes_total{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod"}, host)',
          refresh=$._config.grafanaDashboards.templateRefresh,
          sort=$._config.grafanaDashboards.templateSort,
          includeAll=true,
          multi=true,
        );

      local upstreamTemplate =
        template.new(
          name='upstream',
          label='Upstream',
          datasource='$datasource',
          query='label_values(nginx_vts_upstream_bytes_total{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod"}, upstream)',
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
            prometheus.target('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container!~"POD|"}) by (container)', legendFormat='{{container}}'),
            prometheus.target('sum(\nkube_pod_container_resource_requests{resource="cpu", cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"})', legendFormat='PodRequests'),
            prometheus.target('sum(\nkube_pod_container_resource_limits{resource="cpu", cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"})', legendFormat='PodLimits'),
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
            prometheus.target('sum(container_memory_working_set_bytes{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", id!="", container!~"POD|"}) by (container)', legendFormat='{{container}}'),
            prometheus.target('sum(\nkube_pod_container_resource_requests{resource="memory", cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}) by (container)', legendFormat='PodRequests - {{container}}'),
            prometheus.target('sum(\nkube_pod_container_resource_limits{resource="memory", cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}) by (container)', legendFormat='PodLimits - {{container}}'),
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
        .addTarget(loki.target('sum(count_over_time({cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"} |~ "(?i)$search"[10s])) by (pod)', legendFormat='{{pod}}'));

      local logs =
        logPanel.new(
          title='Logs',
          datasource='$datasource_logs',
          showLabels=true,
        )
        .addTarget(loki.target('{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"} |~ "(?i)$search"'));

      local serverConnections =
        graphPanel.new(
          title='Server Connections',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('sum(nginx_vts_main_connections{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", status=~"active|writing|reading|waiting"}) by (status)', legendFormat='{{status}}'));

      local serverCache =
        graphPanel.new(
          title='Server Cache',
          datasource='$datasource',
          min=0,
        )
        .addTarget(prometheus.target('sum(irate(nginx_vts_server_cache_total{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", host=~"^$host$"}[5m])) by (status)', legendFormat='{{status}}'));

      local serverRequests =
        graphPanel.new(
          title='Server Requests',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('sum(irate(nginx_vts_server_requests_total{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", host=~"^$host$", code!="total"}[5m])) by (code)', legendFormat='{{code}}'));

      local serverBytes =
        graphPanel.new(
          title='Server Bytes',
          datasource='$datasource',
          format='bytes',
          min=0,
        )
        .addTarget(prometheus.target('sum(irate(nginx_vts_server_bytes_total{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", host=~"^$host$"}[5m])) by (direction)', legendFormat='{{direction}}'));

      local upstreamRequests =
        graphPanel.new(
          title='Upstream Requests',
          datasource='$datasource',
          description="This one is providing aggregated error codes, but it's still possible to graph these per upstream.",
        )
        .addTarget(prometheus.target('sum(irate(nginx_vts_upstream_requests_total{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", upstream=~"^$upstream$", code!="total"}[5m])) by (code)', legendFormat='{{code}}'));

      local upstreamBytes =
        graphPanel.new(
          title='Upstream Bytes',
          datasource='$datasource',
          format='bytes',
          min=0,
        )
        .addTarget(prometheus.target('sum(irate(nginx_vts_upstream_bytes_total{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", upstream=~"^$upstream$"}[5m])) by (direction)', legendFormat='{{direction}}'));

      local upstreamBackendResponse =
        graphPanel.new(
          title='Upstream Backend Response',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('sum(nginx_vts_upstream_response_seconds{cluster=~"$cluster", job=~"$job", namespace=~"$namespace", pod=~"$pod", upstream=~"^$upstream$"}) by (backend)', legendFormat='{{backend}}'));

      local templates =
        [
          $.grafanaTemplates.datasourceTemplate(),
        ]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.datasourceLogsTemplate()] else [])
        + [
          $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
          $.grafanaTemplates.jobTemplate('label_values(nginx_vts_server_bytes_total{cluster=~"$cluster"}, job)'),
          $.grafanaTemplates.namespaceTemplate('label_values(nginx_vts_server_bytes_total{cluster=~"$cluster", job=~"$job"}, namespace)'),
          $.grafanaTemplates.podTemplate('label_values(nginx_vts_server_bytes_total{cluster=~"$cluster", job=~"$job", namespace=~"$namespace"}, pod)'),
          hostTemplate,
          upstreamTemplate,
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
        serverConnections { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 6, w: 12, h: 7 } },
        serverCache { tooltip+: { sort: 2 }, gridPos: { x: 12, y: 6, w: 12, h: 7 } },
        serverRequests { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 13, w: 12, h: 7 } },
        serverBytes { tooltip+: { sort: 2 }, gridPos: { x: 12, y: 13, w: 12, h: 7 } },
        row.new('Upstream', collapse=true) { gridPos: { x: 0, y: 20, w: 24, h: 1 } }
        .addPanel(upstreamRequests { tooltip+: { sort: 2 } }, { x: 0, y: 21, w: 12, h: 7 })
        .addPanel(upstreamBytes { tooltip+: { sort: 2 } }, { x: 12, y: 21, w: 12, h: 7 })
        .addPanel(upstreamBackendResponse { tooltip+: { sort: 2 } }, { x: 0, y: 28, w: 24, h: 7 }),
      ] + if $._config.grafanaDashboards.isLoki then logsPanels else [];

      dashboard.new(
        'Nginx VTS Enhanced',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.nginxVtsEnhanced,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
