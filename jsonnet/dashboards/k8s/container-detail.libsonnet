/*
  Copyright 2020 The K8s-m8g Authors. All Rights Reserved.
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
local template = grafana.template;
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
          linewidth=2,
          fill=2,
        )
        .addTargets(
          [
            prometheus.target('sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", container=~"$container"}) by ($view)', legendFormat='{{$view}}'),
            prometheus.target('sum(kube_pod_container_resource_requests_cpu_cores{namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='PodRequests - {{$view}}'),
            prometheus.target('sum(kube_pod_container_resource_limits_cpu_cores{namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='PodLimits - {{$view}}'),
          ]
        )
        .addSeriesOverride({ alias: '/PodRequests/', color: '#F2495C', dashes: true, fill: 0, legend: true, linewidth: 2, stack: false })
        .addSeriesOverride({ alias: '/PodLimits/', color: '#FF9830', dashes: true, fill: 0, legend: true, linewidth: 2, stack: false });

      local memory =
        graphPanel.new(
          title='Memory Usage',
          datasource='$datasource',
          min=0,
          format='bytes',
          stack=true,
          linewidth=2,
          fill=2,
        )
        .addTargets(
          [
            prometheus.target('sum(container_memory_working_set_bytes{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container!="POD", id!="", container=~"$container"}) by ($view)', legendFormat='{{$view}}'),
            prometheus.target('sum(kube_pod_container_resource_requests_memory_bytes{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='PodRequests - {{$view}}'),
            prometheus.target('sum(kube_pod_container_resource_limits_memory_bytes{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"}) by ($view)', legendFormat='PodLimits - {{$view}}'),
          ]
        )
        .addSeriesOverride({ alias: '/PodRequests/', dashes: true, fill: 0, legend: true, linewidth: 2, stack: false })
        .addSeriesOverride({ alias: '/PodLimits/', dashes: true, fill: 0, legend: true, linewidth: 2, stack: false });

      local bandwidth =
        graphPanel.new(
          title='Transmit/Receive Bandwidth',
          datasource='$datasource',
          format='Bps',
          stack=true,
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
          legend_alignAsTable=true,
          legend_current=true,
          legend_rightSide=true,
        )
        .addTarget(loki.target('sum(count_over_time( ({cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search" )[10s] )) by ($view)', legendFormat='{{$view}}'));

      local logs =
        logPanel.new(
          title='Logs',
          datasource='$datasource_logs',
          showLabels=true,
        )
        .addTarget(loki.target('{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod", container=~"$container"} |~ "(?i)$search"'));

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
          query='label_values(kube_pod_container_info{cluster=~"$cluster"}, namespace)',
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
          query='label_values(kube_pod_container_info{cluster=~"$cluster", namespace=~"$namespace"}, pod)',
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
          query='label_values(kube_pod_container_info{cluster=~"$cluster", namespace=~"$namespace", pod=~"$pod"}, container)',
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

      local clusterTemplate =
        template.new(
          name='cluster',
          label='Cluster',
          query='label_values(kube_pod_container_info, cluster)',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local templates = [
                          datasourceTemplate,
                        ]
                        + (if $._config.isLoki then [datasourceLogsTemplate] else [])
                        + [
                          viewByTemplate,
                          namespaceTemplate,
                          podTemplate,
                          containerTemplate,
                          clusterTemplate,
                        ]
                        + if $._config.isLoki then [searchTemplate] else [];

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
      ] + if $._config.isLoki then logsPanels else [];

      dashboard.new(
        'Container Detail',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sDetail,
        uid=$._config.dashboardIDs.containerDetail,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
