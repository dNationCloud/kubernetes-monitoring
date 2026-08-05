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
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local gaugePanel = grafana.panel.gauge;
local table = grafana.panel.table;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;
local fieldOverride = grafana.panel.timeSeries.fieldOverride;

{
  grafanaDashboards+:: {
    'node-exporter':
      local promTarget(expr, legendFormat=null) = prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local statBase(title, expr, unit, decimals=null, graphMode='area') =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit(unit)
        + (if decimals != null then statPanel.standardOptions.withDecimals(decimals) else {})
        + statPanel.options.withGraphMode(graphMode)
        + statPanel.options.reduceOptions.withCalcs(['mean'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps([{ color: $._config.grafanaDashboards.color.blue, value: null }])
        + statPanel.queryOptions.withTargets([promTarget(expr)]);

      local gaugeBase(title, expr, unit=null, min=null, max=null, desc=null) =
        gaugePanel.new(title)
        + gaugePanel.queryOptions.withDatasource('prometheus', '$datasource')
        + (if unit != null then gaugePanel.standardOptions.withUnit(unit) else {})
        + (if min != null then gaugePanel.standardOptions.withMin(min) else {})
        + (if max != null then gaugePanel.standardOptions.withMax(max) else {})
        + (if desc != null then gaugePanel.panelOptions.withDescription(desc) else {})
        + gaugePanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + gaugePanel.standardOptions.thresholds.withMode('absolute')
        + gaugePanel.standardOptions.thresholds.withSteps([{ color: $._config.grafanaDashboards.color.blue, value: null }])
        + gaugePanel.queryOptions.withTargets([promTarget(expr)]);

      local timeSeriesBase(title, unit=null, min=null, max=null, fillOpacity=10, desc=null, overrides=[]) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + (if min != null then timeSeriesPanel.standardOptions.withMin(min) else {})
        + (if max != null then timeSeriesPanel.standardOptions.withMax(max) else {})
        + (if desc != null then timeSeriesPanel.panelOptions.withDescription(desc) else {})
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(fillOpacity)
        + (if std.length(overrides) > 0 then timeSeriesPanel.standardOptions.withOverrides(overrides) else {})
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc');

      local upTimePanel = statBase('Uptime', 'avg(time() - node_boot_time_seconds{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 's', 0, graphMode='none');
      local cpuCoresPanel = statBase('CPU Cores', 'count(node_cpu_seconds_total{cluster="$cluster", job=~"$job", mode="system"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'short');
      local memoryPanel = statBase('Memory', 'sum(node_memory_MemTotal_bytes{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'bytes', 0);
      local cpuUtilPanel = gaugeBase('CPU Utilization', 'round((1 - (avg(irate(node_cpu_seconds_total{cluster="$cluster", job=~"$job", mode="idle"}[5m]) * on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))))) * 100)', 'percent', 0, 100);
      local memUtilPanel = gaugeBase('Memory Utilization', 'round((1 - (sum(node_memory_MemAvailable_bytes{cluster="$cluster", job=~"$job"} * on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) / sum(node_memory_MemTotal_bytes{cluster="$cluster", job=~"$job"}* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) )) * 100)', unit='percent', min=0, max=100, desc='The percentage of the memory utilization is calculated by:\n```\n1 - (<memory available>/<memory total>)\n```');
      local mostUtilDiskPanel = gaugeBase('Most Utilized Disk', 'round(\nmax(\n(sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job"}) by (instance, device) - sum(node_filesystem_free_bytes{cluster="$cluster", job=~"$job"}) by (instance, device)) /\n(sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job"}) by (instance, device) - sum(node_filesystem_free_bytes{cluster="$cluster", job=~"$job"}) by (instance, device) +\nsum(node_filesystem_avail_bytes{cluster="$cluster", job=~"$job"}) by (instance, device))\n * 100 \n * on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))\n)\n)', unit='percent', min=0, max=100, desc='The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition. See the list of explicitly ignored mount points and file systems [here](https://github.com/dNationCloud/kubernetes-monitoring-stack/blob/main/chart/values.yaml)');
      local networkErrPanel = gaugeBase('Network Errors', 'sum(rate(node_network_transmit_errs_total{cluster="$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]) * on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) + \nsum(rate(node_network_receive_errs_total{cluster="$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]) * on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'pps', 0, 100);

      local ipTable =
        table.new('Table of IP Addresses')
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + table.standardOptions.withOverrides([
          fieldOverride.byName.new('Time')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('Value')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('_0_nodename')
          + fieldOverride.byName.withProperty('displayName', 'Instance'),
          fieldOverride.byName.new('_1_instance')
          + fieldOverride.byName.withProperty('displayName', 'IP Address'),
        ])
        + table.queryOptions.withTargets([prometheus.withExpr('sum by(_1_instance, _0_nodename) (\nlabel_replace(\nlabel_replace(\n  node_uname_info{cluster="$cluster", job=~"$job", nodename=~"$instance"}\n    , "_1_instance", "$1", "instance", "(.*):.*")\n    , "_0_nodename","$1", "nodename", "(.*)")\n)') + prometheus.withFormat('table') + prometheus.withInstant(true)]);

      local hiddenSeries(alias) = fieldOverride.byRegexp.new(alias)
                                    + fieldOverride.byRegexp.withProperty('custom.hideFrom', { viz: true, legend: false, tooltip: false });

      local rightAxisUtil(alias) = fieldOverride.byRegexp.new(alias)
                                     + fieldOverride.byRegexp.withProperty('custom.axisPlacement', 'right')
                                     + fieldOverride.byRegexp.withProperty('unit', 'percent')
                                     + fieldOverride.byRegexp.withProperty('custom.drawStyle', 'points')
                                     + fieldOverride.byRegexp.withProperty('custom.hideFrom', { legend: true, tooltip: false, viz: false });

      local cpuUtilGraphPanel = timeSeriesBase('CPU Utilization', 'percent', 0, 100)
                                + timeSeriesPanel.queryOptions.withTargets([promTarget('round((1 - (avg by (nodename) (irate(node_cpu_seconds_total{cluster="$cluster", job=~"$job", mode="idle"}[5m])\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))))) * 100)', 'cpu  - {{nodename}}')]);

      local loadAverageGraphPanel = timeSeriesBase('Load Average', min=0, fillOpacity=0, overrides=[fieldOverride.byRegexp.new('/logical cores/')
                                                                                                      + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: '#C4162A' })
                                                                                                      + fieldOverride.byRegexp.withProperty('custom.lineWidth', 2)])
                                    + timeSeriesPanel.queryOptions.withTargets([
                                      promTarget('sum by (nodename) (node_load1{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', '1m load average {{nodename}}'),
                                      promTarget('sum by (nodename) (node_load5{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', '5m load average {{nodename}}'),
                                      promTarget('sum by (nodename) (node_load15{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', '15m load average {{nodename}}'),
                                      promTarget('count by (nodename) (node_cpu_seconds_total{cluster="$cluster", job=~"$job", mode="idle"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'logical cores {{nodename}}'),
                                    ]);

      local memUtilGraphPanel = timeSeriesBase('Memory Utilization', 'bytes', 0, desc='The used memory is calculated by:\n```\n<memory total> - <memory available>\n```', overrides=[
                                  fieldOverride.byRegexp.new('/total/')
                                    + fieldOverride.byRegexp.withProperty('color', { mode: 'fixed', fixedColor: '#C4162A' })
                                    + fieldOverride.byRegexp.withProperty('custom.fillOpacity', 0)
                                    + fieldOverride.byRegexp.withProperty('custom.lineWidth', 2),
                                  hiddenSeries('/available/'),
                                  hiddenSeries('/buffers/'),
                                  hiddenSeries('/cached/'),
                                  hiddenSeries('/free/'),
                                ])
                                + timeSeriesPanel.queryOptions.withTargets([
                                  promTarget('sum by (nodename) (node_memory_MemTotal_bytes{cluster="$cluster", job=~"$job"}* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) - sum by (nodename) (node_memory_MemAvailable_bytes{cluster="$cluster", job=~"$job"} * on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'memory used - {{nodename}}'),
                                  promTarget('sum by (nodename) (node_memory_MemAvailable_bytes{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'memory available - {{nodename}}'),
                                  promTarget('sum by (nodename) (node_memory_Buffers_bytes{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'memory buffers - {{nodename}}'),
                                  promTarget('sum by (nodename) (node_memory_Cached_bytes{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'memory cached - {{nodename}}'),
                                  promTarget('sum by (nodename) (node_memory_MemFree_bytes{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'memory free - {{nodename}}'),
                                  promTarget('sum by (nodename) (node_memory_MemTotal_bytes{cluster="$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'memory total - {{nodename}}'),
                                ]);

      local diskDesc = 'The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition.';

      local diskOverrides = [fieldOverride.byRegexp.new('/size/')
                               + fieldOverride.byRegexp.withProperty('custom.fillOpacity', 0)
                               + fieldOverride.byRegexp.withProperty('custom.lineWidth', 2), hiddenSeries('/available/'), rightAxisUtil('/utilization/')];

      local diskUtilGraphPanel = timeSeriesBase('Disk Utilization', 'bytes', 0, desc=diskDesc + ' See the list of types of displayed disk filesystems [here](https://github.com/dNationCloud/kubernetes-monitoring/blob/main/jsonnet/dashboards/grafana-templates.libsonnet) and list of explicitly ignored mount points and file systems at node-exporter level [here](https://github.com/dNationCloud/kubernetes-monitoring-stack/blob/main/chart/values.yaml)', overrides=diskOverrides)
                                 + timeSeriesPanel.queryOptions.withTargets([
                                   promTarget('sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job", fstype=~"$diskfs"} * on(instance) group_left(nodename) (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) by (device, instance, nodename, mountpoint)  - sum(node_filesystem_free_bytes{cluster="$cluster", job=~"$job", fstype=~"$diskfs"} * on(instance) group_left(nodename) (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) by (device, instance, nodename, mountpoint)', 'disk used {{device}} {{nodename}} {{mountpoint}}'),
                                   promTarget('sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job", fstype=~"$diskfs"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) by (device, instance, nodename, mountpoint)', 'disk size {{device}} {{nodename}} {{mountpoint}}'),
                                   promTarget('sum(node_filesystem_avail_bytes{cluster="$cluster", job=~"$job", fstype=~"$diskfs"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) by (device, instance, nodename, mountpoint)', 'disk available {{device}} {{nodename}} {{mountpoint}}'),
                                   promTarget('round((sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job", fstype=~"$diskfs"}) by (device, instance, nodename, mountpoint) - sum(node_filesystem_free_bytes{cluster="$cluster", job=~"$job", fstype=~"$diskfs"}) by (device, instance, nodename, mountpoint)) / (sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job", fstype=~"$diskfs"}) by (device, instance, nodename, mountpoint) - sum(node_filesystem_free_bytes{cluster="$cluster", job=~"$job", fstype=~"$diskfs"}) by (device, instance, nodename, mountpoint) + sum(node_filesystem_avail_bytes{cluster="$cluster", job=~"$job"}) by (device, instance, nodename, mountpoint)) * 100 * on(instance) group_left(nodename) (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'disk utilization {{device}} {{nodename}} {{mountpoint}}'),
                                 ]);

      local virtualFilesystemsUtilGraphPanel = timeSeriesBase('Disk Utilization (Virtual Filesystems)', 'bytes', 0, desc=diskDesc + ' See the list of explicitly ignored mount points and file systems at grafana level [here](https://github.com/dNationCloud/kubernetes-monitoring/blob/main/jsonnet/dashboards/grafana-templates.libsonnet) and at node-exporter level [here](https://github.com/dNationCloud/kubernetes-monitoring-stack/blob/main/chart/values.yaml)', overrides=diskOverrides)
                                               + timeSeriesPanel.queryOptions.withTargets([
                                                 promTarget('sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job", fstype!~"$diskfs"} * on(instance) group_left(nodename) (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) by (device, instance, nodename)  - sum(node_filesystem_free_bytes{cluster="$cluster", job=~"$job", fstype!~"$diskfs"} * on(instance) group_left(nodename) (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) by (device, instance, nodename)', 'disk used {{device}} {{nodename}} {{mountpoint}}'),
                                                 promTarget('sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job", fstype!~"$diskfs"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) by (device, instance, nodename)', 'disk size {{device}} {{nodename}} {{mountpoint}}'),
                                                 promTarget('sum(node_filesystem_avail_bytes{cluster="$cluster", job=~"$job", fstype!~"$diskfs"}\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))) by (device, instance, nodename)', 'disk available {{device}} {{nodename}} {{mountpoint}}'),
                                                 promTarget('round((sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job", fstype!~"$diskfs"}) by (device, instance, nodename) - sum(node_filesystem_free_bytes{cluster="$cluster", job=~"$job", fstype!~"$diskfs"}) by (device, instance, nodename)) / (sum(node_filesystem_size_bytes{cluster="$cluster", job=~"$job", fstype!~"$diskfs"}) by (device, instance, nodename) - sum(node_filesystem_free_bytes{cluster="$cluster", job=~"$job", fstype!~"$diskfs"}) by (device, instance, nodename) + sum(node_filesystem_avail_bytes{cluster="$cluster", job=~"$job", fstype!~"$diskfs"}) by (device, instance, nodename)) * 100 * on(instance) group_left(nodename) (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename)))', 'disk utilization {{device}} {{nodename}} {{mountpoint}}'),
                                               ]);

      local diskIOGraphPanel = timeSeriesBase('Disk I/O', 'bytes', fillOpacity=0, overrides=[fieldOverride.byRegexp.new('/read*|written*/')
                                                                                               + fieldOverride.byRegexp.withProperty('custom.axisPlacement', 'left'), fieldOverride.byRegexp.new('/io time*/')
                                                                                                                                                                        + fieldOverride.byRegexp.withProperty('custom.axisPlacement', 'right')
                                                                                                                                                                        + fieldOverride.byRegexp.withProperty('unit', 's')])
                               + timeSeriesPanel.queryOptions.withTargets([
                                 promTarget('sum(rate(node_disk_read_bytes_total{cluster="$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))', 'read {{device}} {{nodename}}'),
                                 promTarget('sum(rate(node_disk_written_bytes_total{cluster="$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))', 'written {{device}} {{nodename}}'),
                                 promTarget('sum(rate(node_disk_io_time_seconds_total{cluster="$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))', 'io time {{device}} {{nodename}}'),
                               ]);

      local transRecGraphPanel = timeSeriesBase('Transmit/Receive Errors', 'pps', fillOpacity=0, overrides=[fieldOverride.byRegexp.new('/Rx_/')
                                                                                                              + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'B' })
                                                                                                              + fieldOverride.byRegexp.withProperty('custom.transform', 'negative-Y'), fieldOverride.byRegexp.new('/Tx_/')
                                                                                                                                                                                         + fieldOverride.byRegexp.withProperty('custom.stacking', { mode: 'normal', group: 'A' })])
                                 + timeSeriesPanel.queryOptions.withTargets([
                                   promTarget('rate(node_network_transmit_errs_total{cluster="$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))', 'Tx_{{device}} {{nodename}}'),
                                   promTarget('rate(node_network_receive_errs_total{cluster="$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))', 'Rx_{{device}} {{nodename}}'),
                                 ]);

      local netRecGraphPanel = timeSeriesBase('Network Received', 'bytes', 0, fillOpacity=0)
                               + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(node_network_receive_bytes_total{cluster="$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))', '{{device}} {{nodename}}')]);

      local netTransGraphPanel = timeSeriesBase('Network Transmitted', 'bytes', 0, fillOpacity=0)
                                 + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(node_network_transmit_bytes_total{cluster="$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   (avg(node_uname_info{cluster="$cluster", nodename=~"$instance"}) by (instance,nodename))', '{{device}} {{nodename}}')]);

      dashboard.new('Node Exporter')
      + dashboard.withUid($._config.grafanaDashboards.ids.nodeExporter)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sNodeExporter)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(node_uname_info{cluster="$cluster"}, job)'),
        $.grafanaTemplates.instanceTemplate('label_values(node_uname_info{cluster="$cluster", job=~"$job"}, nodename)'),
        $.grafanaTemplates.diskFileSystemsTemplate(),
      ])
      + dashboard.withPanels([
        row.new('Overview') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        upTimePanel { gridPos: { x: 0, y: 1, w: 4, h: 3 } },
        cpuUtilPanel { gridPos: { x: 4, y: 1, w: 5, h: 5 } },
        memUtilPanel { gridPos: { x: 9, y: 1, w: 5, h: 5 } },
        mostUtilDiskPanel { gridPos: { x: 14, y: 1, w: 5, h: 5 } },
        networkErrPanel { gridPos: { x: 19, y: 1, w: 5, h: 5 } },
        cpuCoresPanel { gridPos: { x: 0, y: 4, w: 2, h: 2 } },
        memoryPanel { gridPos: { x: 2, y: 4, w: 2, h: 2 } },
        ipTable { gridPos: { x: 0, y: 6, w: 24, h: 5 } },
        row.new('CPU Utilization / Load Average') + { gridPos: { x: 0, y: 11, w: 24, h: 1 } },
        cpuUtilGraphPanel { gridPos: { x: 0, y: 12, w: 24, h: 7 } },
        loadAverageGraphPanel { gridPos: { x: 0, y: 19, w: 24, h: 7 } },
        row.new('Memory Utilization') + { gridPos: { x: 0, y: 26, w: 24, h: 1 } },
        memUtilGraphPanel { gridPos: { x: 0, y: 27, w: 24, h: 7 } },
        row.new('Disk Utilization') + { gridPos: { x: 0, y: 34, w: 24, h: 1 } },
        diskUtilGraphPanel { gridPos: { x: 0, y: 35, w: 24, h: 7 } },
        virtualFilesystemsUtilGraphPanel { gridPos: { x: 0, y: 42, w: 24, h: 7 } },
        diskIOGraphPanel { gridPos: { x: 0, y: 49, w: 24, h: 7 } },
        row.new('Network') + { gridPos: { x: 0, y: 56, w: 24, h: 1 } },
        transRecGraphPanel { gridPos: { x: 0, y: 57, w: 24, h: 7 } },
        netRecGraphPanel { gridPos: { x: 0, y: 64, w: 24, h: 7 } },
        netTransGraphPanel { gridPos: { x: 0, y: 71, w: 24, h: 7 } },
      ]),
  },
}
