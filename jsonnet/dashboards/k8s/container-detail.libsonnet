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

/* K8s container detail dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local loki = grafana.loki;
local graphPanel = grafana.graphPanel;
local logPanel = grafana.logPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    'container-detail':
      local cpu =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          min=0,
          format='cores',
          stack=true,
          nullPointMode='null as zero',
          linewidth=2,
          fill=2,
        )
        .addTargets(
          [
            prometheus.target('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", container=~"$container"}) by ($view)', legendFormat='{{$view}}'),
            prometheus.target('sum(kube_pod_container_resource_requests{resource="cpu", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='PodRequests - {{$view}}'),
            prometheus.target('sum(kube_pod_container_resource_limits{resource="cpu", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='PodLimits - {{$view}}'),
          ]
        )
        .addSeriesOverride({ alias: '/PodRequests/', color: $._config.grafanaDashboards.color.red, dashes: true, fill: 0, stack: false, hideTooltip: true })
        .addSeriesOverride({ alias: '/PodLimits/', color: $._config.grafanaDashboards.color.orange, dashes: true, fill: 0, stack: false, hideTooltip: true });

      local memory =
        graphPanel.new(
          title='Memory Usage',
          datasource='$datasource',
          min=0,
          format='bytes',
          stack=true,
          nullPointMode='null as zero',
          linewidth=2,
          fill=2,
        )
        .addTargets(
          [
            prometheus.target('sum(container_memory_working_set_bytes{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", id!="", container=~"$container"}) by ($view)', legendFormat='{{$view}}'),
            prometheus.target('sum(kube_pod_container_resource_requests{resource="memory", cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='PodRequests - {{$view}}'),
            prometheus.target('sum(kube_pod_container_resource_limits{resource="memory", cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='PodLimits - {{$view}}'),
          ]
        )
        .addSeriesOverride({ alias: '/PodRequests/', color: $._config.grafanaDashboards.color.red, dashes: true, fill: 0, stack: false, hideTooltip: true })
        .addSeriesOverride({ alias: '/PodLimits/', color: $._config.grafanaDashboards.color.orange, dashes: true, fill: 0, stack: false, hideTooltip: true });

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
        .addTargets(
          [
            prometheus.target('sum(irate(container_network_transmit_bytes_total{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Tx_{{pod}}'),
            prometheus.target('sum(irate(container_network_receive_bytes_total{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Rx_{{pod}}'),
          ]
        )
        .addSeriesOverride({ alias: '/Rx_/', stack: 'B', transform: 'negative-Y' })
        .addSeriesOverride({ alias: '/Tx_/', stack: 'A' });

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
        .addTargets(
          [
            prometheus.target('sum(irate(container_network_transmit_packets_dropped_total{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Tx_{{pod}}'),
            prometheus.target('sum(irate(container_network_receive_packets_dropped_total{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}[5m])) by (pod)', legendFormat='Rx_{{pod}}'),
          ]
        )
        .addSeriesOverride({ alias: '/Rx_/', stack: 'B', transform: 'negative-Y' })
        .addSeriesOverride({ alias: '/Tx_/', stack: 'A' });

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

      local templates =
        [
          $.grafanaTemplates.datasourceTemplate(),
        ]
        + (if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.datasourceLogsTemplate()] else [])
        + [
          $.grafanaTemplates.viewByTemplate('pod,container'),
          $.grafanaTemplates.clusterTemplate('label_values(node_namespace_pod_container:container_memory_working_set_bytes, cluster)'),
          $.grafanaTemplates.instanceTemplate('label_values(node_namespace_pod_container:container_memory_working_set_bytes{cluster=~"$cluster"}, node)', label='Node'),
          $.grafanaTemplates.namespaceTemplate('label_values(node_namespace_pod_container:container_memory_working_set_bytes{cluster=~"$cluster", node=~"$instance"}, namespace)'),
          $.grafanaTemplates.podTemplate('label_values(node_namespace_pod_container:container_memory_working_set_bytes{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace"}, pod)'),
          $.grafanaTemplates.containerTemplate('label_values(node_namespace_pod_container:container_memory_working_set_bytes{cluster=~"$cluster", node=~"$instance", namespace=~"$namespace", pod=~"$pod"}, container)'),
        ]
        + if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.searchTemplate()] else [];

      local logsPanels = [
        row.new('Logs') { gridPos: { x: 0, y: 11, w: 24, h: 1 } },
        count { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 12, w: 24, h: 5 } },
        logs { gridPos: { x: 0, y: 17, w: 24, h: 13 } },
      ];

      local panels = [
        row.new('CPU Usage') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        cpu { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 1, w: 24, h: 7 } },
        row.new('Memory Usage', collapse=true) { gridPos: { x: 0, y: 8, w: 24, h: 1 } }
        .addPanel(memory { tooltip+: { sort: 2 } }, { x: 0, y: 9, w: 24, h: 7 }),
        row.new('Network Bandwidth', collapse=true) { gridPos: { x: 0, y: 9, w: 24, h: 1 } }
        .addPanel(bandwidth { tooltip+: { sort: 2 } }, { x: 0, y: 10, w: 24, h: 7 }),
        row.new('Network Drops', collapse=true) { gridPos: { x: 0, y: 10, w: 24, h: 1 } }
        .addPanel(drops { tooltip+: { sort: 2 } }, { x: 0, y: 11, w: 24, h: 7 }),
      ] + if $._config.grafanaDashboards.isLoki then logsPanels else [];

      dashboard.new(
        'Container Detail',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sContainer,
        uid=$._config.grafanaDashboards.ids.containerDetail,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
