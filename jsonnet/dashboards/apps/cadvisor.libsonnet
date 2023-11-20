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
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    cadvisor:
      local containers =
        statPanel.new(
          title='Containers',
          datasource='$datasource',
          graphMode='none',
        )
        .addThresholds($.grafanaThresholds($._config.templates.L1.hostApps.genericApp.panel.thresholds))
        .addTarget(
          prometheus.target('count(rate(container_last_seen{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m]))')
        );

      local imageTable =
        table.new(
          title='',
          datasource='$datasource',
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Name', pattern: 'name', type: 'string' },
            { alias: 'Image', pattern: 'image', type: 'string' },
            { pattern: 'Value', type: 'hidden' },
          ]
        )
        .addTarget(prometheus.target(format='table', instant=true, expr='sum(container_cpu_user_seconds_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}) by (name,image)'));

      local cpu =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          format='percent',
          min=0,
          max=100,
          stack=true,
          nullPointMode='null as zero',
          linewidth=2,
          fill=2,
        )
        .addTarget(prometheus.target('rate(container_cpu_user_seconds_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m]) * 100', legendFormat='{{name}}'));

      local memory =
        graphPanel.new(
          title='Memory Utilization',
          datasource='$datasource',
          format='bytes',
          min=0,
          linewidth=2,
          fill=2,
        )
        .addTarget(prometheus.target('container_memory_usage_bytes{cluster="$cluster", job=~"$job", image!="", name=~"$container"}', legendFormat='{{name}}'));

      local containerDiskUsage =
        graphPanel.new(
          title='Container Disk Usage',
          datasource='$datasource',
          format='bytes',
          linewidth=2,
          fill=2,
          min=0,
        )
        .addTarget(prometheus.target('container_fs_usage_bytes{cluster="$cluster", job=~"$job", image!="", name=~"$container"}', legendFormat='{{name}}'));

      local DiskIO =
        graphPanel.new(
          title='Disk I/O',
          datasource='$datasource',
          formatY1='bytes',
          formatY2='s',
          fill=0,
        )
        .addSeriesOverride({ alias: '/read*|written*/', yaxis: 1 })
        .addSeriesOverride({ alias: '/io time*/', yaxis: 2 })
        .addTargets(
          [
            prometheus.target('sum(rate(container_fs_reads_bytes_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])) by (name)', legendFormat='read {{name}}'),
            prometheus.target('sum(rate(container_fs_writes_bytes_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])) by (name)', legendFormat='written {{name}}'),
            prometheus.target('sum(rate(container_fs_io_time_seconds_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])) by (name)', legendFormat='io time {{name}}'),
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
            prometheus.target('irate(container_network_transmit_bytes_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Tx_{{name}}'),
            prometheus.target('irate(container_network_receive_bytes_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Rx_{{name}}'),
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
            prometheus.target('irate(container_network_transmit_packets_dropped_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Tx_{{name}}'),
            prometheus.target('irate(container_network_receive_packets_dropped_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Rx_{{name}}'),
          ],
        );

      local errors =
        graphPanel.new(
          title='Transmit/Receive Errors',
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
            prometheus.target('irate(container_network_transmit_errors_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Tx_{{name}}'),
            prometheus.target('irate(container_network_receive_errors_total{cluster="$cluster", job=~"$job", image!="", name=~"$container"}[5m])', legendFormat='Rx_{{name}}'),
          ],
        );

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
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.cAdvisor,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(container_cpu_user_seconds_total{cluster="$cluster"}, job)'),
        $.grafanaTemplates.containerTemplate('label_values(container_cpu_user_seconds_total{cluster="$cluster", job=~"$job"}, name)'),
      ])
      .addPanels(panels),
  },
}
