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

/* K8s L2 node overview dashboards */

local grafana = (import 'grafonnet/grafana.libsonnet')
                + (import 'grafonnet-polystat-panel/plugin.libsonnet');
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local row = grafana.row;
local graphPanel = grafana.graphPanel;
local polystatPanel = grafana.polystatPanel;

{
  grafanaDashboards+::
    local polystatOverviewDashboard(dashboardUid, dashboardName, mainTemplate, grafanaTemplates, customParams) = {
      local templatePanel = mainTemplate.panel,
      local polyPanel =
        polystatPanel.new(
          title=templatePanel.title,
          datasource=templatePanel.datasource,
          description=templatePanel.description,
          default_click_through=templatePanel.default_click_through,
          global_unit_format=templatePanel.global_unit_format,
          global_thresholds=templatePanel.global_thresholds,
          hexagon_sort_by_direction=templatePanel.hexagon_sort_by_direction,
          hexagon_sort_by_field=templatePanel.hexagon_sort_by_field,
          polygon_border_size=templatePanel.polygon_border_size,
          tooltip_timestamp_enabled=templatePanel.tooltip_timestamp_enabled,
        )
        .addTarget(prometheus.target(legendFormat='{{nodename}}', expr=templatePanel.expr))
        {
          gridPos: templatePanel.gridPos,
          polystat+: {
            globalDecimals: templatePanel.globalDecimals,
            fontAutoColor: templatePanel.fontAutoColor,
            fontColor: templatePanel.fontColor,
          },
        },

      dashboard:
        dashboard.new(
          dashboardName,
          editable=$._config.grafanaDashboards.editable,
          graphTooltip=$._config.grafanaDashboards.tooltip,
          refresh=$._config.grafanaDashboards.refresh,
          time_from=$._config.grafanaDashboards.time_from,
          tags=$._config.grafanaDashboards.tags.k8sOverview,
          uid=dashboardUid,
        )
        .addTemplates(grafanaTemplates)
        .addPanels(
          [
            polyPanel,
            row.new('$instance', repeat='instance', collapse=true) { gridPos: { x: 0, y: 6, w: 24, h: 1 } }
            .addPanels(customParams.instancePanels),
          ]
        ),
    };

    //network-ovierview instance panels
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
          prometheus.target(legendFormat='Tx_{{device}}', expr='rate(node_network_transmit_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          prometheus.target(legendFormat='Rx_{{device}}', expr='rate(node_network_receive_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
        ]
      )
      { tooltip+: { sort: 2 } }
      { gridPos: { x: 0, y: 7, w: 24, h: 7 } };

    local netRecGraphPanel =
      graphPanel.new(
        title='Network Received',
        datasource='$datasource',
        format='bytes',
        fill=0,
        min=0,
      )
      .addTarget(prometheus.target(legendFormat='{{device}}', expr='rate(node_network_receive_bytes_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'))
      { tooltip+: { sort: 2 } }
      { gridPos: { x: 0, y: 14, w: 24, h: 7 } };

    local netTransGraphPanel =
      graphPanel.new(
        title='Network Transmitted',
        datasource='$datasource',
        format='bytes',
        fill=0,
        min=0,
      )
      .addTarget(prometheus.target(legendFormat='{{device}}', expr='rate(node_network_transmit_bytes_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'))
      { tooltip+: { sort: 2 } }
      { gridPos: { x: 0, y: 21, w: 24, h: 7 } };

    //memory-overview instance panels
    local memUtilGraphPanel =
      graphPanel.new(
        title='Memory Utilization',
        description='The used memory is calculated by:\n```\n<memory total> - <memory available>\n```',
        datasource='$datasource',
        format='bytes',
        min=0,
      )
      .addSeriesOverride({ alias: '/total/', color: '#C4162A', fill: 0, linewidth: 2 })
      .addSeriesOverride({ alias: '/available/', hiddenSeries: true })
      .addSeriesOverride({ alias: '/buffers/', hiddenSeries: true })
      .addSeriesOverride({ alias: '/cached/', hiddenSeries: true })
      .addSeriesOverride({ alias: '/free/', hiddenSeries: true })
      .addTargets(
        [
          prometheus.target(legendFormat='memory used', expr='sum by (nodename) (node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}) - sum by (nodename) (node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"$job"} * on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
          prometheus.target(legendFormat='memory available', expr='sum by (nodename) (node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
          prometheus.target(legendFormat='memory buffers', expr='sum by (nodename) (node_memory_Buffers_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
          prometheus.target(legendFormat='memory cached', expr='sum by (nodename) (node_memory_Cached_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
          prometheus.target(legendFormat='memory free', expr='sum by (nodename) (node_memory_MemFree_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
          prometheus.target(legendFormat='memory total', expr='sum by (nodename) (node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
        ]
      )
      { tooltip+: { sort: 2 } }
      { gridPos: { x: 0, y: 7, w: 24, h: 7 } };

    //disk-overview instance panels
    local diskUtilGraphPanel =
      graphPanel.new(
        title='Disk Utilization',
        description='The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition\n.\n                       See the list of explicitly ignored mount points and file systems [here](https://github.com/dNationCloud/kubernetes-monitoring-stack/blob/main/chart/values.yaml)',
        datasource='$datasource',
        formatY1='bytes',
        formatY2='percent',
        min=0,
      )
      .addSeriesOverride({ alias: '/size/', fill: 0, linewidth: 2 })
      .addSeriesOverride({ alias: '/available/', hiddenSeries: true })
      .addSeriesOverride({ alias: '/utilization/', yaxis: 2, lines: false, legend: false, pointradius: 0 })
      .addTargets(
        [
          prometheus.target(legendFormat='disk used {{device}}', expr='(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job"}) by (device, instance) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job"}) by (device, instance))\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          prometheus.target(legendFormat='disk size {{device}}', expr='sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job"}) by (device, instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          prometheus.target(legendFormat='disk available {{device}}', expr='sum(node_filesystem_avail_bytes{cluster=~"$cluster", job=~"$job"}) by (device, instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          prometheus.target(legendFormat='disk utilization {{device}}', expr='round((sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job"}) by (device, instance, nodename) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job"}) by (device, instance, nodename)) / (sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job"}) by (device, instance, nodename) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job"}) by (device, instance, nodename) + sum(node_filesystem_avail_bytes{cluster=~"$cluster", job=~"$job"}) by (device, instance, nodename)) * 100 * on(instance) group_left(nodename) node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
        ]
      )
      { yaxes: std.mapWithIndex(function(i, item) if (i == 1) then item { show: false } else item, super.yaxes) }  // Hide second Y axis
      { tooltip+: { sort: 2 } }
      { gridPos: { x: 0, y: 7, w: 24, h: 7 } };

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
          prometheus.target(legendFormat='read {{device}}', expr='sum(rate(node_disk_read_bytes_total{cluster=~"$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          prometheus.target(legendFormat='written {{device}}', expr='sum(rate(node_disk_written_bytes_total{cluster=~"$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          prometheus.target(legendFormat='io time {{device}}', expr='sum(rate(node_disk_io_time_seconds_total{cluster=~"$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
        ]
      )
      { tooltip+: { sort: 2 } }
      { gridPos: { x: 0, y: 14, w: 24, h: 7 } };

    //cpu-overview instance panels
    local cpuUtilGraphPanel =
      graphPanel.new(
        title='CPU Utilization',
        datasource='$datasource',
        stack=true,
        format='percent',
        min=0,
        max=100,
      )
      .addTarget(prometheus.target(legendFormat='cpu usage', expr='round((1 - (avg(irate(node_cpu_seconds_total{cluster=~"$cluster", job=~"$job", mode="idle"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}))) * 100)'))
      { tooltip+: { sort: 2 } }
      { gridPos: { x: 0, y: 7, w: 24, h: 7 } };

    local loadAvgGraphPanel =
      graphPanel.new(
        title='Load Average',
        datasource='$datasource',
        fill=0,
        min=0,
      )
      .addSeriesOverride({ alias: 'logical cores', linewidth: 2, color: '#C4162A' })
      .addTargets(
        [
          prometheus.target(legendFormat='1m load average', expr='node_load1{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          prometheus.target(legendFormat='5m load average', expr='node_load5{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          prometheus.target(legendFormat='15m load average', expr='node_load15{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          prometheus.target(legendFormat='logical cores', expr='count(node_cpu_seconds_total{cluster=~"$cluster", job=~"$job", mode="idle"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
        ]
      )
      { tooltip+: { sort: 2 } }
      { gridPos: { x: 0, y: 14, w: 24, h: 7 } };

    $.createOverviewDashboards(
      jsonName='network-overview',
      dashboardFunction=polystatOverviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.networkOverview,
      dashboardName='Network per Node',
      templateName='networkPerNodePolystat',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.nodeTemplate,
      instancePanels=[transRecGraphPanel, netRecGraphPanel, netTransGraphPanel],
      grafanaTemplates=[
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(node_exporter_build_info{cluster=~"$cluster", pod!~"virt-launcher.*|"}, job)', hide='variable'),
      ]
    ) +

    $.createOverviewDashboards(
      jsonName='memory-overview',
      dashboardFunction=polystatOverviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.memoryOverview,
      dashboardName='Memory per Node',
      templateName='memoryPerNodePolystat',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.nodeTemplate,
      instancePanels=[memUtilGraphPanel],
      grafanaTemplates=[
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(node_exporter_build_info{cluster=~"$cluster", pod!~"virt-launcher.*|"}, job)', hide='variable'),
      ]
    ) +

    $.createOverviewDashboards(
      jsonName='disk-overview',
      dashboardFunction=polystatOverviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.diskOverview,
      dashboardName='Disk per Node',
      templateName='diskPerNodePolystat',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.nodeTemplate,
      instancePanels=[diskUtilGraphPanel, diskIOGraphPanel],
      grafanaTemplates=[
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(node_exporter_build_info{cluster=~"$cluster", pod!~"virt-launcher.*|"}, job)', hide='variable'),
      ]
    ) +

    $.createOverviewDashboards(
      jsonName='cpu-overview',
      dashboardFunction=polystatOverviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.cpuOverview,
      dashboardName='CPU per Node',
      templateName='cpuPerNodePolystat',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.nodeTemplate,
      instancePanels=[cpuUtilGraphPanel, loadAvgGraphPanel],
      grafanaTemplates=[
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(node_exporter_build_info{cluster=~"$cluster", pod!~"virt-launcher.*|"}, job)', hide='variable'),
      ]
    ),

}
