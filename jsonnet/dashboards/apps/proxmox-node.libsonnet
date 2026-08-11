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

/* Proxmox node dashboard (node_exporter + smartctl_exporter) */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local table = grafana.panel.table;
local fieldOverride = grafana.panel.table.fieldOverride;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    'proxmox-node':
      local color = $._config.grafanaDashboards.color;

      local commonSelector = 'cluster="$cluster", job=~"$job", instance=~"$instance"';
      local smartctlSelector = 'cluster="$cluster", instance=~"$instance"';

      local promTarget(expr, legendFormat=null, instant=false) =
        prometheus.withExpr(expr)
        + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {})
        + (if instant then prometheus.withInstant(true) else {});

      local tableTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr) + prometheus.withFormat('table') + prometheus.withInstant(true)
        + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local statBase(title, expr, steps, mapOptions=null, unit='none', desc=null, legendFormat=null) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit(unit)
        + statPanel.options.withColorMode('background')
        + statPanel.options.withGraphMode('none')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps(steps)
        + (if mapOptions != null then statPanel.standardOptions.withMappings([{ type: 'value', options: mapOptions }]) else {})
        + (if desc != null then statPanel.panelOptions.withDescription(desc) else {})
        + statPanel.queryOptions.withTargets([promTarget(expr, legendFormat, instant=true)]);

      local timeSeriesBase(title, targets, labelY1=null, unit=null, decimals=null, min=null, max=null, desc=null) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + (if labelY1 != null then timeSeriesPanel.fieldConfig.defaults.custom.withAxisLabel(labelY1) else {})
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + (if decimals != null then timeSeriesPanel.standardOptions.withDecimals(decimals) else {})
        + (if min != null then timeSeriesPanel.standardOptions.withMin(min) else {})
        + (if max != null then timeSeriesPanel.standardOptions.withMax(max) else {})
        + (if desc != null then timeSeriesPanel.panelOptions.withDescription(desc) else {})
        + timeSeriesPanel.queryOptions.withTargets(targets);

      local commonHidden = ['job', '__name__', 'Time', 'cluster', 'container', 'endpoint', 'namespace', 'pod', 'prometheus', 'prometheus_replica', 'service', 'instance', 'id'];

      local hide(name) =
        fieldOverride.byName.new(name)
        + fieldOverride.byName.withProperty('custom.hidden', true);

      local rename(name, disp) =
        fieldOverride.byName.new(name)
        + fieldOverride.byName.withProperty('displayName', disp);

      local show(name, disp) =
        fieldOverride.byName.new(name)
        + fieldOverride.byName.withProperty('displayName', disp)
        + fieldOverride.byName.withProperty('custom.hidden', false);

      local valueCol(name, disp, unit, decimals=1, width=null) =
        fieldOverride.byName.new(name)
        + fieldOverride.byName.withProperty('displayName', disp)
        + fieldOverride.byName.withProperty('unit', unit)
        + fieldOverride.byName.withProperty('decimals', decimals)
        + (if width != null then fieldOverride.byName.withProperty('custom.width', width) else {});

      local statusCol(name, disp, mapOptions, steps, width) =
        fieldOverride.byName.new(name)
        + fieldOverride.byName.withProperty('displayName', disp)
        + fieldOverride.byName.withProperty('mappings', [{ type: 'value', options: mapOptions }])
        + fieldOverride.byName.withProperty('custom.cellOptions', { type: 'color-background' })
        + fieldOverride.byName.withProperty('thresholds', { mode: 'absolute', steps: steps })
        + fieldOverride.byName.withProperty('custom.width', width);

      local tableBase(title, desc, overrides, transformations, targets) =
        table.new(title)
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + (if desc != null then table.panelOptions.withDescription(desc) else {})
        + table.standardOptions.withOverrides([hide(n) for n in commonHidden] + overrides)
        + table.queryOptions.withTransformations(transformations)
        + table.queryOptions.withTargets(targets);

      local upMap = { '0': { text: 'Down', color: color.red }, '1': { text: 'Up', color: color.green }, '-1': { text: '-' } };
      local countSteps = [{ color: 'transparent', value: null }];
      local statusSteps = [{ color: color.red, value: null }, { color: color.green, value: 1 }];

      local nodesOnlinePanel =
        statBase('Nodes online',
                 'count(up{%s} == 1) OR on() vector(-1)' % commonSelector,
                 countSteps,
                 { '-1': { text: '-' } },
                 desc='Nodes whose node_exporter answers scrapes.');

      local nodesTablePanel =
        tableBase('Nodes',
                  'Basic inventory of the nodes as reported by node_exporter.',
                  [
                    show('instance', 'Node'),
                    statusCol('Value #A', 'Status', upMap, statusSteps, 90),
                    valueCol('Value #B', 'Cores', 'none', 0, 80),
                    valueCol('Value #C', 'Memory total', 'bytes', 1, 130),
                    valueCol('Value #D', 'Root FS used', 'percent', 1, 120),
                    valueCol('Value #E', 'Uptime', 's', 0, 130),
                  ],
                  [{ id: 'merge', options: { reducers: [] } }],
                  [
                    tableTarget('max by (instance) (up{%s})' % commonSelector),
                    tableTarget('count by (instance) (node_cpu_seconds_total{mode="idle", %s})' % commonSelector),
                    tableTarget('max by (instance) (node_memory_MemTotal_bytes{%s})' % commonSelector),
                    tableTarget('max by (instance) ((1 - node_filesystem_avail_bytes{mountpoint="/", %s} / node_filesystem_size_bytes{mountpoint="/", %s}) * 100)' % [commonSelector, commonSelector]),
                    tableTarget('max by (instance) (node_time_seconds{%s} - node_boot_time_seconds{%s})' % [commonSelector, commonSelector]),
                  ]);

      local cpuPanel =
        timeSeriesBase('CPU usage',
                       [promTarget('(1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle", %s}[5m]))) * 100' % commonSelector, '{{instance}}')],
                       labelY1='CPU',
                       unit='percent',
                       decimals=1,
                       min=0,
                       max=100);

      local memoryPanel =
        timeSeriesBase('Memory usage',
                       [promTarget('(1 - node_memory_MemAvailable_bytes{%s} / node_memory_MemTotal_bytes{%s}) * 100' % [commonSelector, commonSelector], '{{instance}}')],
                       labelY1='Memory',
                       unit='percent',
                       decimals=1,
                       min=0,
                       max=100);

      local loadPanel =
        timeSeriesBase('Load 1m',
                       [promTarget('node_load1{%s}' % commonSelector, '{{instance}}')],
                       labelY1='Load',
                       min=0);

      local filesystemPanel =
        timeSeriesBase('Filesystem usage',
                       [promTarget('(1 - node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs", %s} / node_filesystem_size_bytes{fstype!~"tmpfs|ramfs", %s}) * 100' % [commonSelector, commonSelector], '{{instance}} {{mountpoint}}')],
                       labelY1='Used',
                       unit='percent',
                       decimals=1,
                       min=0,
                       max=100);

      local diskIOPanel =
        timeSeriesBase('Disk I/O',
                       [
                         promTarget('rate(node_disk_read_bytes_total{%s}[5m])' % commonSelector, '{{instance}} {{device}} read'),
                         promTarget('rate(node_disk_written_bytes_total{%s}[5m])' % commonSelector, '{{instance}} {{device}} written'),
                       ],
                       labelY1='Throughput',
                       unit='Bps',
                       min=0);

      local networkPanel =
        timeSeriesBase('Network I/O',
                       [
                         promTarget('rate(node_network_receive_bytes_total{device!~"lo", %s}[5m])' % commonSelector, '{{instance}} {{device}} received'),
                         promTarget('rate(node_network_transmit_bytes_total{device!~"lo", %s}[5m])' % commonSelector, '{{instance}} {{device}} sent'),
                       ],
                       labelY1='Throughput',
                       unit='Bps',
                       min=0);

      local smartDevicesPanel =
        statBase('Monitored disks',
                 'sum(smartctl_devices{%s}) OR on() vector(-1)' % smartctlSelector,
                 countSteps,
                 { '-1': { text: '-' } },
                 desc='Disks discovered by smartctl_exporter across all nodes. Virtual disks do not expose SMART, so this is 0 on VM based test clusters.');

      local smartIssuesPanel =
        statBase('Disks failing SMART',
                 'count(smartctl_device_smart_status{%s} == 0) OR on() vector(0)' % smartctlSelector,
                 [{ color: color.green, value: null }, { color: color.red, value: 1 }],
                 {},
                 desc='Disks whose overall SMART self-assessment is failed. 0 also when no SMART capable disks are present.');

      local smartTablePanel =
        tableBase('Disks',
                  'SMART overview per disk: overall health, current temperature and the NVMe wearout (percentage used) estimate.',
                  [
                    show('instance', 'Node'),
                    rename('device', 'Device'),
                    statusCol('Value #A', 'SMART status',
                              { '0': { text: 'Failed', color: color.red }, '1': { text: 'Passed', color: color.green } },
                              statusSteps, 110),
                    valueCol('Value #B', 'Temperature', 'celsius', 0, 110),
                    valueCol('Value #C', 'Wearout used', 'percent', 0, 110),
                  ],
                  [{ id: 'merge', options: { reducers: [] } }],
                  [
                    tableTarget('max by (instance, device) (smartctl_device_smart_status{%s})' % smartctlSelector),
                    tableTarget('max by (instance, device) (smartctl_device_temperature{temperature_type="current", %s})' % smartctlSelector),
                    tableTarget('max by (instance, device) (smartctl_device_percentage_used{%s})' % smartctlSelector),
                  ]);

      local smartTemperaturePanel =
        timeSeriesBase('Disk temperature',
                       [promTarget('smartctl_device_temperature{temperature_type="current", %s}' % smartctlSelector, '{{instance}} {{device}}')],
                       labelY1='Temperature',
                       unit='celsius',
                       decimals=0,
                       min=0);

      local smartWearoutPanel =
        timeSeriesBase('Disk wearout (percentage used)',
                       [promTarget('smartctl_device_percentage_used{%s}' % smartctlSelector, '{{instance}} {{device}}')],
                       labelY1='Used',
                       unit='percent',
                       decimals=0,
                       min=0,
                       max=100,
                       desc='NVMe endurance estimate: 100 % means the rated write endurance is exhausted.');

      local panels = [
        row.new('Overview') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        nodesOnlinePanel { gridPos: { x: 0, y: 1, w: 4, h: 5 } },
        nodesTablePanel { gridPos: { x: 4, y: 1, w: 20, h: 5 } },
        row.new('CPU & Memory') + { gridPos: { x: 0, y: 6, w: 24, h: 1 } },
        cpuPanel { gridPos: { x: 0, y: 7, w: 8, h: 7 } },
        memoryPanel { gridPos: { x: 8, y: 7, w: 8, h: 7 } },
        loadPanel { gridPos: { x: 16, y: 7, w: 8, h: 7 } },
        row.new('Disk & Network') + { gridPos: { x: 0, y: 14, w: 24, h: 1 } },
        filesystemPanel { gridPos: { x: 0, y: 15, w: 8, h: 7 } },
        diskIOPanel { gridPos: { x: 8, y: 15, w: 8, h: 7 } },
        networkPanel { gridPos: { x: 16, y: 15, w: 8, h: 7 } },
        row.new('SMART (disk health)') + { gridPos: { x: 0, y: 22, w: 24, h: 1 } },
        smartDevicesPanel { gridPos: { x: 0, y: 23, w: 4, h: 4 } },
        smartIssuesPanel { gridPos: { x: 4, y: 23, w: 4, h: 4 } },
        smartTablePanel { gridPos: { x: 8, y: 23, w: 16, h: 6 } },
        smartTemperaturePanel { gridPos: { x: 0, y: 29, w: 12, h: 7 } },
        smartWearoutPanel { gridPos: { x: 12, y: 29, w: 12, h: 7 } },
      ];

      dashboard.new('Proxmox VE Nodes')
      + dashboard.withUid($._config.grafanaDashboards.ids.proxmoxNode)
      + dashboard.withLinks([
        dashboard.link.link.withTitle('Proxmox VE Overview')
        + dashboard.link.link.withType('link')
        + dashboard.link.link.withUrl('/d/%s?var-datasource=$datasource&var-cluster=$cluster' % $._config.grafanaDashboards.ids.proxmox)
        + dashboard.link.link.withIcon('dashboard')
        + dashboard.link.link.options.withKeepTime(true)
        + dashboard.link.link.options.withIncludeVars(false)
        + dashboard.link.link.options.withTargetBlank(false),
      ])
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(node_uname_info{cluster="$cluster"}, job)'),
        $.grafanaTemplates.instanceTemplate('label_values(node_uname_info{cluster="$cluster", job=~"$job"}, instance)'),
      ])
      + dashboard.withPanels(panels),
  },
}
