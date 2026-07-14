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
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local polystatPanel = (import 'grafonnet-polystat-panel/plugin.libsonnet').polystatPanel;
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;
local fieldOverride = grafana.panel.timeSeries.fieldOverride;

{
  grafanaDashboards+::
    local promTarget(expr, legendFormat=null) = prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

    local hiddenSeries(alias) = fieldOverride.byRegexp.new(alias)
                                  + fieldOverride.byRegexp.withProperty('custom.hideFrom', { viz: true, legend: false, tooltip: false });

    local timeSeriesBase(title, unit=null, min=null, max=null, fillOpacity=10, stack=false, desc=null, overrides=[]) =
      timeSeriesPanel.new(title)
      + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
      + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
      + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
      + (if min != null then timeSeriesPanel.standardOptions.withMin(min) else {})
      + (if max != null then timeSeriesPanel.standardOptions.withMax(max) else {})
      + (if desc != null then timeSeriesPanel.panelOptions.withDescription(desc) else {})
      + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(fillOpacity)
      + (if stack then timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' }) else {})
      + (if std.length(overrides) > 0 then timeSeriesPanel.standardOptions.withOverrides(overrides) else {})
      + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc');

    local polystatOverviewDashboard(dashboardUid, dashboardName, mainTemplate, grafanaTemplates, customParams) = {
      local templatePanel = mainTemplate.panel,

      local polyPanel =
        polystatPanel.new(
          title=templatePanel.title,
          datasource=templatePanel.datasource,
          description=templatePanel.description,
          default_click_through=$.addRefreshParam(templatePanel.default_click_through),
          global_unit_format=templatePanel.global_unit_format,
          global_thresholds=templatePanel.global_thresholds,
          hexagon_sort_by_direction=templatePanel.hexagon_sort_by_direction,
          hexagon_sort_by_field=templatePanel.hexagon_sort_by_field,
          polygon_border_size=templatePanel.polygon_border_size,
          tooltip_timestamp_enabled=templatePanel.tooltip_timestamp_enabled,
        )
        .addTarget(prometheus.withExpr(templatePanel.expr) + prometheus.withLegendFormat('{{nodename}}') + prometheus.withFormat('time_series') + prometheus.withIntervalFactor(2))
        {
          gridPos: templatePanel.gridPos,
          polystat+: {
            globalDecimals: templatePanel.globalDecimals,
            fontAutoColor: templatePanel.fontAutoColor,
            fontColor: templatePanel.fontColor,
          },
        },

      dashboard:
        dashboard.new(dashboardName)
        + dashboard.withUid(dashboardUid)
        + dashboard.withTags($._config.grafanaDashboards.tags.k8sOverview)
        + dashboard.withEditable($._config.grafanaDashboards.editable)
        + dashboard.withRefresh($._config.grafanaDashboards.refresh)
        + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
        + $._config.grafanaDashboards.tooltip
        + dashboard.withTimezone('browser')
        + dashboard.withVariables(grafanaTemplates)
        + dashboard.withPanels([
          polyPanel,
          row.new('$instance') + row.withRepeat('instance') + row.withCollapsed(true) + { gridPos: { x: 0, y: 6, w: 24, h: 1 } }
          + row.withPanels(customParams.instancePanels),
        ]),
    };

    local transRecGraphPanel = timeSeriesBase('Transmit/Receive Errors', 'pps', fillOpacity=0, overrides=[
      fieldOverride.byRegexp.new('/Rx_/')
        + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'B' })
        + fieldOverride.byRegexp.withProperty('custom.transform', 'negative-Y'),
      fieldOverride.byRegexp.new('/Tx_/')
        + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'A' }),
    ]) + timeSeriesPanel.queryOptions.withTargets([
      promTarget('rate(node_network_transmit_errs_total{cluster="$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', 'Tx_{{device}}'),
      promTarget('rate(node_network_receive_errs_total{cluster="$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', 'Rx_{{device}}'),
    ]) + { gridPos: { x: 0, y: 7, w: 24, h: 7 } };

    local netRecGraphPanel = timeSeriesBase('Network Received', 'bytes', min=0, fillOpacity=0)
                             + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(node_network_receive_bytes_total{cluster="$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', '{{device}}')]) + { gridPos: { x: 0, y: 14, w: 24, h: 7 } };

    local netTransGraphPanel = timeSeriesBase('Network Transmitted', 'bytes', min=0, fillOpacity=0)
                               + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(node_network_transmit_bytes_total{cluster="$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', '{{device}}')]) + { gridPos: { x: 0, y: 21, w: 24, h: 7 } };

    local memUtilGraphPanel = timeSeriesBase('Memory Utilization', 'bytes', min=0, desc='The used memory is calculated by:\n```\n<memory total> - <memory available>\n```', overrides=[
      fieldOverride.byRegexp.new('/total/')
        + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: '#C4162A' })
        + fieldOverride.byRegexp.withProperty('custom.fillOpacity', 0)
        + fieldOverride.byRegexp.withProperty('custom.lineWidth', 2),
      hiddenSeries('/available/'),
      hiddenSeries('/buffers/'),
      hiddenSeries('/cached/'),
      hiddenSeries('/free/'),
    ]) + timeSeriesPanel.queryOptions.withTargets([
      promTarget('sum by (nodename) (node_memory_MemTotal_bytes{cluster="$cluster", job=~"$job"}* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}) - sum by (nodename) (node_memory_MemAvailable_bytes{cluster="$cluster", job=~"$job"} * on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"})', 'memory used'),
      promTarget('sum by (nodename) (node_memory_MemAvailable_bytes{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"})', 'memory available'),
      promTarget('sum by (nodename) (node_memory_Buffers_bytes{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"})', 'memory buffers'),
      promTarget('sum by (nodename) (node_memory_Cached_bytes{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"})', 'memory cached'),
      promTarget('sum by (nodename) (node_memory_MemFree_bytes{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"})', 'memory free'),
      promTarget('sum by (nodename) (node_memory_MemTotal_bytes{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"})', 'memory total'),
    ]) + { gridPos: { x: 0, y: 7, w: 24, h: 7 } };

    local diskUtilGraphPanel = timeSeriesBase('Disk Utilization', 'bytes', min=0, desc='The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition\n.\n                       See the list of explicitly ignored mount points and file systems [here](https://github.com/dNationCloud/kubernetes-monitoring-stack/blob/main/chart/values.yaml)', overrides=[
      fieldOverride.byRegexp.new('/size/')
        + fieldOverride.byRegexp.withProperty('custom.fillOpacity', 0)
        + fieldOverride.byRegexp.withProperty('custom.lineWidth', 2),
      hiddenSeries('/available/'),
      fieldOverride.byRegexp.new('/utilization/')
        + fieldOverride.byRegexp.withProperty('custom.axisPlacement', 'right')
        + fieldOverride.byRegexp.withProperty('unit', 'percent')
        + fieldOverride.byRegexp.withProperty('custom.drawStyle', 'points')
        + fieldOverride.byRegexp.withProperty('custom.hideFrom', { legend: true, tooltip: false, viz: false }),
    ]) + timeSeriesPanel.queryOptions.withTargets([
      promTarget('(sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job"}) by (device, instance) - sum(node_filesystem_free_bytes{cluster="$cluster", job=~"$job"}) by (device, instance))\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', 'disk used {{device}}'),
      promTarget('sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job"}) by (device, instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', 'disk size {{device}}'),
      promTarget('sum(node_filesystem_avail_bytes{cluster="$cluster", job=~"$job"}) by (device, instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', 'disk available {{device}}'),
      promTarget('round((sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job"}) by (device, instance, nodename) - sum(node_filesystem_free_bytes{cluster="$cluster", job=~"$job"}) by (device, instance, nodename)) / (sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job"}) by (device, instance, nodename) - sum(node_filesystem_free_bytes{cluster="$cluster", job=~"$job"}) by (device, instance, nodename) + sum(node_filesystem_avail_bytes{cluster="$cluster", job=~"$job"}) by (device, instance, nodename)) * 100 * on(instance) group_left(nodename) node_uname_info{cluster="$cluster", nodename=~"$instance"})', 'disk utilization {{device}}'),
    ]) + { gridPos: { x: 0, y: 7, w: 24, h: 7 } };

    local diskIOGraphPanel = timeSeriesBase('Disk I/O', 'bytes', fillOpacity=0, overrides=[
      fieldOverride.byRegexp.new('/read*|written*/')
        + fieldOverride.byRegexp.withProperty('custom.axisPlacement', 'left'),
      fieldOverride.byRegexp.new('/io time*/')
        + fieldOverride.byRegexp.withProperty('custom.axisPlacement', 'right')
        + fieldOverride.byRegexp.withProperty('unit', 's'),
    ]) + timeSeriesPanel.queryOptions.withTargets([
      promTarget('sum(rate(node_disk_read_bytes_total{cluster="$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', 'read {{device}}'),
      promTarget('sum(rate(node_disk_written_bytes_total{cluster="$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', 'written {{device}}'),
      promTarget('sum(rate(node_disk_io_time_seconds_total{cluster="$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', 'io time {{device}}'),
    ]) + { gridPos: { x: 0, y: 14, w: 24, h: 7 } };

    local cpuUtilGraphPanel = timeSeriesBase('CPU Utilization', 'percent', min=0, max=100, stack=true)
                              + timeSeriesPanel.queryOptions.withTargets([promTarget('round((1 - (avg(irate(node_cpu_seconds_total{cluster="$cluster", job=~"$job", mode="idle"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}))) * 100)', 'cpu usage')]) + { gridPos: { x: 0, y: 7, w: 24, h: 7 } };

    local loadAvgGraphPanel = timeSeriesBase('Load Average', min=0, fillOpacity=0, overrides=[fieldOverride.byRegexp.new('logical cores')
                                                                                                + fieldOverride.byRegexp.withProperty('custom.lineWidth', 2)
                                                                                                + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: '#C4162A' })])
                              + timeSeriesPanel.queryOptions.withTargets([
                                promTarget('node_load1{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', '1m load average'),
                                promTarget('node_load5{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', '5m load average'),
                                promTarget('node_load15{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"}', '15m load average'),
                                promTarget('count(node_cpu_seconds_total{cluster="$cluster", job=~"$job", mode="idle"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster="$cluster", nodename=~"$instance"})', 'logical cores'),
                              ]) + { gridPos: { x: 0, y: 14, w: 24, h: 7 } };

    local baseTpls = [
      $.grafanaTemplates.datasourceTemplate(),
      $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
      $.grafanaTemplates.jobTemplate('label_values(node_exporter_build_info{cluster="$cluster", pod!~"virt-launcher.*|"}, job)', hide='variable'),
    ];

    $.createOverviewDashboards(
      jsonName='network-overview',
      dashboardFunction=polystatOverviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.networkOverview,
      dashboardName='Network per Node',
      templateName='networkPerNodePolystat',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.nodeTemplate,
      instancePanels=[transRecGraphPanel, netRecGraphPanel, netTransGraphPanel],
      grafanaTemplates=baseTpls,
    )
    + $.createOverviewDashboards(
      jsonName='memory-overview',
      dashboardFunction=polystatOverviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.memoryOverview,
      dashboardName='Memory per Node',
      templateName='memoryPerNodePolystat',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.nodeTemplate,
      instancePanels=[memUtilGraphPanel],
      grafanaTemplates=baseTpls,
    )
    + $.createOverviewDashboards(
      jsonName='disk-overview',
      dashboardFunction=polystatOverviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.diskOverview,
      dashboardName='Disk per Node',
      templateName='diskPerNodePolystat',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.nodeTemplate,
      instancePanels=[diskUtilGraphPanel, diskIOGraphPanel],
      grafanaTemplates=baseTpls,
    )
    + $.createOverviewDashboards(
      jsonName='cpu-overview',
      dashboardFunction=polystatOverviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.cpuOverview,
      dashboardName='CPU per Node',
      templateName='cpuPerNodePolystat',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.nodeTemplate,
      instancePanels=[cpuUtilGraphPanel, loadAvgGraphPanel],
      grafanaTemplates=baseTpls,
    ),
}
