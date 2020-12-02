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

/* K8s node exporter dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local statPanel = grafana.statPanel;
local gaugePanel = grafana.gaugePanel;
local graphPanel = grafana.graphPanel;
local template = grafana.template;
local row = grafana.row;

{
  grafanaDashboards+:: {
    'node-exporter':
      local upTimePanel =
        statPanel.new(
          title='Uptime',
          datasource='$datasource',
          graphMode='none',
          decimals=0,
          unit='s',
        )
        .addThresholds(
          [
            { color: $._config.grafanaDashboards.color.red, value: null },
            { color: $._config.grafanaDashboards.color.orange, value: 1 },
            { color: $._config.grafanaDashboards.color.green, value: 3 },
          ]
        )
        .addTarget(prometheus.target('avg(time() - node_boot_time_seconds{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'));

      local cpuCoresPanel =
        statPanel.new(
          title='CPU Cores',
          datasource='$datasource',
          unit='short',
        )
        .addThresholds(
          [
            { color: $._config.grafanaDashboards.color.red, value: null },
            { color: $._config.grafanaDashboards.color.orange, value: 1 },
            { color: $._config.grafanaDashboards.color.green, value: 2 },
          ]
        )
        .addTarget(prometheus.target('count(node_cpu_seconds_total{cluster=~"$cluster", job=~"$job", mode="system"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'));

      local memoryPanel =
        statPanel.new(
          title='Memory',
          datasource='$datasource',
          decimals=0,
          unit='bytes',
        )
        .addThresholds(
          [
            { color: $._config.grafanaDashboards.color.red, value: null },
            { color: $._config.grafanaDashboards.color.orange, value: 2 },
            { color: $._config.grafanaDashboards.color.green, value: 3 },
          ]
        )
        .addTarget(prometheus.target('sum(node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'));

      local cpuUtilPanel =
        gaugePanel.new(
          title='CPU Utilization',
          datasource='$datasource',
        )
        .addThresholds($.grafanaThresholds($._config.templates.nodeCpuUtilization.thresholds))
        .addTarget(prometheus.target('round((1 - (avg(irate(node_cpu_seconds_total{cluster=~"$cluster", job=~"$job", mode="idle"}[5m]) * on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}))) * 100)'));

      local memUtilPanel =
        gaugePanel.new(
          title='Memory Utilization',
          datasource='$datasource',
          description='The percentage of the memory utilization is calculated by:\n```\n1 - (<memory available>/<memory total>)\n```',
          min=0,
          max=100,
        )
        .addThresholds($.grafanaThresholds($._config.templates.nodeRamUtilization.thresholds))
        .addTarget(prometheus.target('round((1 - (sum(node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"$job"} * on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}) / sum(node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}) )) * 100)'));

      local mostUtilDiskPanel =
        gaugePanel.new(
          title='Most Utilized Disk',
          datasource='$datasource',
          description='The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition.',
          min=0,
          max=100,
        )
        .addThresholds($.grafanaThresholds($._config.templates.nodeDiskUtilization.thresholds))
        .addTarget(prometheus.target('round(\nmax(\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device)) /\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device) +\nsum(node_filesystem_avail_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device))\n * 100 \n * on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}\n)\n)'));

      local networkErrPanel =
        gaugePanel.new(
          title='Network Errors',
          datasource='$datasource',
          unit='pps',
          min=0,
          max=100,
        )
        .addThresholds($.grafanaThresholds($._config.templates.nodeNetworkErrors.thresholds))
        .addTarget(prometheus.target('sum(rate(node_network_transmit_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]) * on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}) + \nsum(rate(node_network_receive_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]) * on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'));

      local cpuUtilGraphPanel =
        graphPanel.new(
          title='CPU Utilization',
          datasource='$datasource',
          format='percent',
          min=0,
          max=100,
        )
        .addTarget(prometheus.target(legendFormat='cpu  - {{nodename}}', expr='round((1 - (avg by (nodename) (irate(node_cpu_seconds_total{cluster=~"$cluster", job=~"$job", mode="idle"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}))) * 100)'));

      local loadAverageGraphPanel =
        graphPanel.new(
          title='Load Average',
          datasource='$datasource',
          fill=0,
          min=0,
        )
        .addSeriesOverride({ alias: '/logical cores/', color: '#C4162A', linewidth: 2 })
        .addTargets(
          [
            prometheus.target(legendFormat='1m load average {{nodename}}', expr='sum by (nodename) (node_load1{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='5m load average {{nodename}}', expr='sum by (nodename) (node_load5{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='15m load average {{nodename}}', expr='sum by (nodename) (node_load15{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='logical cores {{nodename}}', expr='count by (nodename) (node_cpu_seconds_total{cluster=~"$cluster", job=~"$job", mode="idle"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
          ]
        );

      local memUtilGraphPanel =
        graphPanel.new(
          title='Memory Utilization',
          description='The used memory is calculated by:\n```\n<memory total> - <memory available>\n```',
          datasource='$datasource',
          format='bytes',
          min=0,
        )
        .addSeriesOverride({ alias: '/total/', color: '#C4162A', fill: 0, linewidth: 2 })
        .addTargets(
          [
            prometheus.target(legendFormat='memory used - {{nodename}}', expr='sum by (nodename) (node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}) - sum by (nodename) (node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"$job"} * on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='memory available - {{nodename}}', expr='sum by (nodename) (node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='memory buffers - {{nodename}}', expr='sum by (nodename) (node_memory_Buffers_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='memory cached - {{nodename}}', expr='sum by (nodename) (node_memory_Cached_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='memory free - {{nodename}}', expr='sum by (nodename) (node_memory_MemFree_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='memory total - {{nodename}}', expr='sum by (nodename) (node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
          ]
        );

      local diskUtilGraphPanel =
        graphPanel.new(
          title='Disk Utilization',
          description='The value of the available disk capacity is reduced by  5%, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition.',
          datasource='$datasource',
          format='bytes',
          min=0,
        )
        .addSeriesOverride({ alias: 'used', color: '#E0B400' })
        .addSeriesOverride({ alias: '/available/', fill: 0, linewidth: 2 })
        .addTargets(
          [
            prometheus.target(legendFormat='used {{device}}  {{nodename}}', expr='(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device, instance, nodename) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device, instance, nodename)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='size {{device}} {{nodename}}', expr='sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}) by (device, instance, nodename)'),
            prometheus.target(legendFormat='available {{device}} {{nodename}}', expr='sum(node_filesystem_avail_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}) by (device, instance, nodename)'),
          ]
        );

      local diskIOGraphPanel =
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
            prometheus.target(legendFormat='read {{device}} {{nodename}}', expr='sum(rate(node_disk_read_bytes_total{cluster=~"$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
            prometheus.target(legendFormat='written {{device}} {{nodename}}', expr='sum(rate(node_disk_written_bytes_total{cluster=~"$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
            prometheus.target(legendFormat='io time {{device}} {{nodename}}', expr='sum(rate(node_disk_io_time_seconds_total{cluster=~"$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          ]
        );

      local transRecGraphPanel =
        graphPanel.new(
          title='Transmit/Receive Errors',
          datasource='$datasource',
          format='pps',
          fill=0,
        )
        .addSeriesOverride({ alias: '/Rx_/', stack: 'B', transform: 'negative-Y' })
        .addSeriesOverride({ alias: '/Tx_/', stack: 'A' })
        .addTargets(
          [
            prometheus.target(legendFormat='Tx_{{device}} {{nodename}}', expr='rate(node_network_transmit_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
            prometheus.target(legendFormat='Rx_{{device}} {{nodename}}', expr='rate(node_network_receive_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          ]
        );

      local netRecGraphPanel =
        graphPanel.new(
          title='Network Received',
          datasource='$datasource',
          format='bytes',
          fill=0,
          min=0,
        )
        .addTarget(prometheus.target(legendFormat='{{device}} {{nodename}}', expr='rate(node_network_receive_bytes_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'));

      local netTransGraphPanel =
        graphPanel.new(
          title='Network Transmitted',
          datasource='$datasource',
          format='bytes',
          fill=0,
          min=0,
        )
        .addTarget(prometheus.target(legendFormat='{{device}} {{nodename}}', expr='rate(node_network_transmit_bytes_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'));

      local datasourceTemplate =
        template.datasource(
          query='prometheus',
          name='datasource',
          current=null,
          label='Datasource',
        );

      local jobTemplate =
        template.new(
          name='job',
          query='label_values(node_uname_info{cluster=~"$cluster"}, job)',
          label='Job',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          includeAll=true,
          multi=true,
        );

      local instanceTemplate =
        template.new(
          name='instance',
          query='label_values(node_uname_info{cluster=~"$cluster", job=~"$job"}, nodename)',
          label='Instance',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          multi=true,
          includeAll=true,
        );

      local clusterTemplate =
        template.new(
          name='cluster',
          query='label_values(node_uname_info, cluster)',
          label='Cluster',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      dashboard.new(
        'Node Exporter',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sNodeExporter,
        uid=$._config.grafanaDashboards.ids.nodeExporter,
      )
      .addTemplates([datasourceTemplate, jobTemplate, instanceTemplate, clusterTemplate])
      .addPanels(
        [
          row.new('Overview') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          upTimePanel { gridPos: { x: 0, y: 1, w: 4, h: 3 } },
          cpuUtilPanel { gridPos: { x: 4, y: 1, w: 5, h: 5 } },
          memUtilPanel { gridPos: { x: 9, y: 1, w: 5, h: 5 } },
          mostUtilDiskPanel { gridPos: { x: 14, y: 1, w: 5, h: 5 } },
          networkErrPanel { gridPos: { x: 19, y: 1, w: 5, h: 5 } },
          cpuCoresPanel { gridPos: { x: 0, y: 4, w: 2, h: 2 } },
          memoryPanel { gridPos: { x: 2, y: 4, w: 2, h: 2 } },
          row.new('CPU Utilization / Load Average') { gridPos: { x: 0, y: 6, w: 24, h: 1 } },
          cpuUtilGraphPanel { gridPos: { x: 0, y: 7, w: 12, h: 7 }, tooltip+: { sort: 2 } },
          loadAverageGraphPanel { gridPos: { x: 12, y: 7, w: 12, h: 7 }, tooltip+: { sort: 2 } },
          row.new('Memory Utilization', collapse=true) { gridPos: { x: 0, y: 14, w: 24, h: 1 } }
          .addPanel(memUtilGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 15, w: 24, h: 7 }),
          row.new('Disk Utilization', collapse=true) { gridPos: { x: 0, y: 15, w: 24, h: 1 } }
          .addPanel(diskUtilGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 23, w: 12, h: 7 })
          .addPanel(diskIOGraphPanel { tooltip+: { sort: 2 } }, { x: 12, y: 23, w: 12, h: 7 }),
          row.new('Network', collapse=true) { gridPos: { x: 0, y: 16, w: 24, h: 1 } }
          .addPanel(transRecGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 31, w: 8, h: 7 })
          .addPanel(netRecGraphPanel { tooltip+: { sort: 2 } }, { x: 8, y: 31, w: 8, h: 7 })
          .addPanel(netTransGraphPanel { tooltip+: { sort: 2 } }, { x: 16, y: 31, w: 8, h: 7 }),
        ]
      ),
  },
}
