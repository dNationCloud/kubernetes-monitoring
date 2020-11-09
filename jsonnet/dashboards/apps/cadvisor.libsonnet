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

/* K8s cadvisor dashboard */
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    cadvisor:
      local datasourceTemplate =
        template.datasource(
          name='datasource',
          label='Datasource',
          query='prometheus',
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
          query='label_values(container_cpu_user_seconds_total{cluster=~"$cluster"}, job)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
        );

      local containerTemplate =
        template.new(
          name='container',
          label='Container',
          datasource='$datasource',
          query='label_values(container_cpu_user_seconds_total{cluster=~"$cluster", job=~"$job"}, name)',
          refresh=$._config.dashboardCommon.templateRefresh,
          sort=$._config.dashboardCommon.templateSort,
          includeAll=true,
          multi=true,
        );

      local containers =
        statPanel.new(
          title='Containers',
          datasource='$datasource',
          graphMode='none',
        )
        .addThresholds($.grafanaThresholds($._config.thresholds.controlPlane))
        .addTarget(
          prometheus.target(expr='count(rate(container_last_seen{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}[5m]))')
        );

      local imageTable =
        table.new(
          title='',
          datasource='$datasource',
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Name', pattern: 'name', type: 'string' },
            { alias: 'Image', pattern: 'image', type: 'string' },
            { alias: 'Value', pattern: 'Value', type: 'hidden' },
          ]
        )
        .addTarget(
          prometheus.target(format='table', instant=true, expr='sum(container_cpu_user_seconds_total{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}) by (name,image)')
        );

      local cpu =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          format='percent',
          min=0,
          stack=true,
          linewidth=2,
          fill=2,
        )
        .addTarget(prometheus.target(expr='rate(container_cpu_user_seconds_total{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}[5m]) * 100', legendFormat='{{name}}'));

      local memory =
        graphPanel.new(
          title='Memory Utilization',
          datasource='$datasource',
          format='bytes',
          min=0,
          linewidth=2,
          fill=2,
        )
        .addSeriesOverride({ alias: '/total/', fill: 0, stack: false, color: $._config.dashboardCommon.color.red })
        .addTarget(prometheus.target(expr='container_memory_usage_bytes{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}', legendFormat='{{name}}'));

      local containerDiskUsage =
        graphPanel.new(
          title='Container Disk Usage',
          datasource='$datasource',
          format='bytes',
          linewidth=2,
          fill=2,
          min=0,
        )
        .addSeriesOverride({ alias: 'used', color: $._config.dashboardCommon.color.yellow })
        .addSeriesOverride({ alias: '/available/', fill: 0 })
        .addTargets([
          prometheus.target(expr='container_fs_usage_bytes{job=~"$job", image!="", name=~"$container"}', legendFormat='{{name}}'),
        ],);

      local DiskIO =
        graphPanel.new(
          title='Disk I/O',
          datasource='$datasource',
          format='bytes',
          linewidth=2,
          fill=2,
        )
        .addSeriesOverride({ alias: '/read*|written*/' })
        .addSeriesOverride({ alias: '/io time*/', yaxis: 2 })
        .addTargets(
          [
            prometheus.target(expr='sum(rate(container_fs_reads_bytes_total{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}[5m])) by (name)', legendFormat='read {{name}}'),
            prometheus.target(expr='sum(rate(container_fs_writes_bytes_total{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}[5m])) by (name)', legendFormat='written {{name}}'),
            prometheus.target(expr='sum(rate(container_fs_io_time_seconds_total{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}[5m])) by (name)', legendFormat='io time {{name}}'),
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
            prometheus.target(expr='irate(container_network_transmit_bytes_total{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Tx_{{name}}'),
            prometheus.target(expr='irate(container_network_receive_bytes_total{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Rx_{{name}}'),
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
            prometheus.target(expr='irate(container_network_transmit_packets_dropped_total{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Tx_{{name}}'),
            prometheus.target(expr='irate(container_network_receive_packets_dropped_total{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Rx_{{name}}'),
          ],
        );

      local errors =
        graphPanel.new(
          title='Transmit/Receive Errors',
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
            prometheus.target(expr='irate(container_network_transmit_errors_total{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Tx_{{name}}'),
            prometheus.target(expr='irate(container_network_receive_errors_total{cluster=~"$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Rx_{{name}}'),
          ],
        );

      local templates = [datasourceTemplate, clusterTemplate, jobTemplate, containerTemplate];

      local panels = [
        row.new('Overview') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        containers { gridPos: { x: 0, y: 1, w: 4, h: 5 } },
        imageTable { gridPos: { x: 4, y: 1, w: 20, h: 5 } },
        row.new('CPU Utilization') { gridPos: { x: 0, y: 6, w: 24, h: 1 } },
        cpu { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 7, w: 24, h: 7 } },
        row.new('Memory Utilization', collapse=true) { gridPos: { x: 0, y: 14, w: 24, h: 1 } }
        .addPanel(memory { tooltip+: { sort: 2 } }, { x: 0, y: 15, w: 24, h: 7 }),
        row.new('Disk Utilization', collapse=true) { gridPos: { x: 0, y: 15, w: 24, h: 1 } }
        .addPanel(containerDiskUsage { tooltip+: { sort: 2 } }, { x: 0, y: 16, w: 12, h: 7 })
        .addPanel(DiskIO { tooltip+: { sort: 2 } }, { x: 12, y: 16, w: 12, h: 7 }),
        row.new('Network Bandwith', collapse=true) { gridPos: { x: 0, y: 16, w: 24, h: 1 } }
        .addPanel(bandwidth { tooltip+: { sort: 2 } }, { x: 0, y: 17, w: 24, h: 7 }),
        row.new('Network Drops', collapse=true) { gridPos: { x: 0, y: 17, w: 24, h: 1 } }
        .addPanel(drops { tooltip+: { sort: 2 } }, { x: 0, y: 18, w: 24, h: 7 }),
        row.new('Network Errors', collapse=true) { gridPos: { x: 0, y: 18, w: 24, h: 1 } }
        .addPanel(errors { tooltip+: { sort: 2 } }, { x: 0, y: 19, w: 24, h: 7 }),
      ];

      dashboard.new(
        'CAdvisor',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sApps,
        uid=$._config.dashboardIDs.cadvisor,
      )
      .addTemplates(templates)
      .addPanels(panels),
  },
}
