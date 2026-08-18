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

/* K8s proxmox dashboard */
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
    proxmox:
      local color = $._config.grafanaDashboards.color;

      local nodeSelector = 'cluster="$cluster", job=~"$job", instance=~"$instance", id=~"node/.*"';
      local storageSelector = 'cluster="$cluster", job=~"$job", instance=~"$instance", id=~"storage/.*"';
      local guestSelector = 'cluster="$cluster", job=~"$job", instance=~"$instance", id=~"(qemu|lxc)/.*"';
      local commonSelector = 'cluster="$cluster", job=~"$job", instance=~"$instance"';

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
      local usageSteps = [{ color: color.green, value: null }, { color: color.orange, value: 75 }, { color: color.red, value: 90 }];
      local countSteps = [{ color: 'transparent', value: null }];
      local statusSteps = [{ color: color.red, value: null }, { color: color.green, value: 1 }];

      local quorumPanel =
        statBase('Cluster quorum',
                 'max(pve_cluster_info{%s, quorate="1"}) OR on() vector(0)' % commonSelector,
                 [{ color: color.red, value: null }, { color: color.green, value: 1 }],
                 { '0': { text: 'No quorum', color: color.red }, '1': { text: 'Quorate', color: color.green } },
                 unit='string',
                 desc='A cluster without quorum cannot start or migrate guests. Reported by the Proxmox cluster status API.');

      local nodesOnlinePanel =
        statBase('Nodes online',
                 'count(pve_up{%s} == 1) OR on() vector(-1)' % nodeSelector,
                 countSteps,
                 { '-1': { text: '-' } });

      local nodesTotalPanel =
        statBase('Nodes total',
                 'count(pve_up{%s}) OR on() vector(-1)' % nodeSelector,
                 countSteps,
                 { '-1': { text: '-' } });

      local versionPanel =
        statBase('Proxmox VE version',
                 'pve_version_info{%s}' % commonSelector,
                 [{ color: color.blue, value: null }],
                 legendFormat='{{version}}')
        + statPanel.options.withTextMode('name');

      local clusterStoragePanel =
        statBase('Storage used',
                 'sum(pve_disk_usage_bytes{%(sel)s}) / sum(pve_disk_size_bytes{%(sel)s}) * 100 OR on() vector(-1)' % { sel: storageSelector },
                 usageSteps,
                 { '-1': { text: '-' } },
                 unit='percent',
                 desc='Sum over all storages. Shared storage is counted once per node that sees it, so the number is indicative; see the storage table for per-storage detail.');

      local guestsRunningPanel =
        statBase('Guests running',
                 'count(pve_up{%s} == 1) OR on() vector(0)' % guestSelector,
                 countSteps,
                 {});

      local guestsTotalPanel =
        statBase('Guests total',
                 'count(pve_guest_info{%s}) OR on() vector(0)' % commonSelector,
                 countSteps,
                 {});

      local nodesTablePanel =
        tableBase('Nodes',
                  'Cluster members with their current load. Uptime, cores and memory come from the Proxmox node status API.',
                  [
                    hide('level'),
                    hide('nodeid'),
                    rename('name', 'Node'),
                    statusCol('Value #A', 'Status', upMap, statusSteps, 90),
                    valueCol('Value #B', 'CPU', 'percent', 1, 90),
                    valueCol('Value #C', 'Cores', 'none', 0, 80),
                    valueCol('Value #D', 'Memory used', 'bytes', 1, 130),
                    valueCol('Value #E', 'Memory total', 'bytes', 1, 130),
                    valueCol('Value #F', 'Uptime', 's', 0, 130),
                  ],
                  [{ id: 'merge', options: { reducers: [] } }],
                  [
                    tableTarget('max by (id, name) (pve_up{%s} * on(id) group_left(name) pve_node_info{%s})' % [nodeSelector, commonSelector]),
                    tableTarget('max by (id) (pve_cpu_usage_ratio{%s}) * 100' % nodeSelector),
                    tableTarget('max by (id) (pve_cpu_usage_limit{%s})' % nodeSelector),
                    tableTarget('max by (id) (pve_memory_usage_bytes{%s})' % nodeSelector),
                    tableTarget('max by (id) (pve_memory_size_bytes{%s})' % nodeSelector),
                    tableTarget('max by (id) (pve_uptime_seconds{%s})' % nodeSelector),
                  ]);

      local nodeCpuPanel =
        timeSeriesBase('Node CPU usage',
                       [promTarget('(pve_cpu_usage_ratio{%s} * on(id) group_left(name) pve_node_info{%s}) * 100' % [nodeSelector, commonSelector], '{{name}}')],
                       labelY1='CPU',
                       unit='percent',
                       decimals=1,
                       min=0,
                       max=100);

      local nodeMemoryPanel =
        timeSeriesBase('Node memory usage',
                       [promTarget('(pve_memory_usage_bytes{%s} / pve_memory_size_bytes{%s} * on(id) group_left(name) pve_node_info{%s}) * 100' % [nodeSelector, nodeSelector, commonSelector], '{{name}}')],
                       labelY1='Memory',
                       unit='percent',
                       decimals=1,
                       min=0,
                       max=100);

      local nodeDiskPanel =
        timeSeriesBase('Node root filesystem usage',
                       [promTarget('(pve_disk_usage_bytes{%s} / pve_disk_size_bytes{%s} * on(id) group_left(name) pve_node_info{%s}) * 100' % [nodeSelector, nodeSelector, commonSelector], '{{name}}')],
                       labelY1='Disk',
                       unit='percent',
                       decimals=1,
                       min=0,
                       max=100,
                       desc='Root filesystem of the node itself, not the storages it serves.');

      local storageTablePanel =
        tableBase('Storages',
                  'Storages as seen by each node. Shared storages (for example Ceph pools) appear once per node.',
                  [
                    rename('storage', 'Storage'),
                    rename('node', 'Node'),
                    rename('plugintype', 'Type'),
                    rename('content', 'Content'),
                    statusCol('Value #A', 'Status', upMap, statusSteps, 90),
                    statusCol('Value #B', 'Shared', { '0': { text: 'Local' }, '1': { text: 'Shared' } }, [{ color: 'transparent', value: null }], 90),
                    valueCol('Value #C', 'Used', 'bytes', 1, 110),
                    valueCol('Value #D', 'Total', 'bytes', 1, 110),
                    valueCol('Value #E', 'Used %', 'percent', 1, 100),
                  ],
                  [{ id: 'merge', options: { reducers: [] } }],
                  [
                    tableTarget('max by (id, storage, node, plugintype, content) (pve_up{%s} * on(id) group_left(storage, node, plugintype, content) pve_storage_info{%s})' % [storageSelector, commonSelector]),
                    tableTarget('max by (id) (pve_storage_shared{%s})' % storageSelector),
                    tableTarget('max by (id) (pve_disk_usage_bytes{%s})' % storageSelector),
                    tableTarget('max by (id) (pve_disk_size_bytes{%s})' % storageSelector),
                    tableTarget('max by (id) (pve_disk_usage_bytes{%s} / pve_disk_size_bytes{%s}) * 100' % [storageSelector, storageSelector]),
                  ]);

      local storageUsagePanel =
        timeSeriesBase('Storage usage',
                       [promTarget('(pve_disk_usage_bytes{%s} / pve_disk_size_bytes{%s} * on(id) group_left(storage, node) pve_storage_info{%s}) * 100' % [storageSelector, storageSelector, commonSelector], '{{node}} / {{storage}}')],
                       labelY1='Usage',
                       unit='percent',
                       decimals=1,
                       min=0,
                       max=100);

      local guestsTablePanel =
        tableBase('Guests',
                  'Virtual machines and containers. Empty until the first guest is created on the cluster.',
                  [
                    rename('name', 'Guest'),
                    rename('type', 'Type'),
                    rename('node', 'Node'),
                    statusCol('Value #A', 'Status', upMap, statusSteps, 90),
                    valueCol('Value #B', 'Cores', 'none', 0, 80),
                    valueCol('Value #C', 'Memory used', 'bytes', 1, 130),
                    valueCol('Value #D', 'Memory total', 'bytes', 1, 130),
                    valueCol('Value #E', 'Disk total', 'bytes', 1, 120),
                    valueCol('Value #F', 'Uptime', 's', 0, 130),
                    statusCol('Value #G', 'Start on boot', { '0': { text: 'No' }, '1': { text: 'Yes' } }, [{ color: 'transparent', value: null }], 120),
                    statusCol('Value #H', 'Backup', { '1': { text: 'Missing', color: color.orange } }, [{ color: 'transparent', value: null }], 100),
                  ],
                  [{ id: 'merge', options: { reducers: [] } }],
                  [
                    tableTarget('max by (id, name, type, node) (pve_up{%s} * on(id) group_left(name, type, node) pve_guest_info{%s})' % [guestSelector, commonSelector]),
                    tableTarget('max by (id) (pve_cpu_usage_limit{%s})' % guestSelector),
                    tableTarget('max by (id) (pve_memory_usage_bytes{%s})' % guestSelector),
                    tableTarget('max by (id) (pve_memory_size_bytes{%s})' % guestSelector),
                    tableTarget('max by (id) (pve_disk_size_bytes{%s})' % guestSelector),
                    tableTarget('max by (id) (pve_uptime_seconds{%s})' % guestSelector),
                    tableTarget('max by (id) (pve_onboot_status{%s})' % commonSelector),
                    tableTarget('max by (id) (pve_not_backed_up_info{%s})' % commonSelector),
                  ]);

      local guestLocksPanel =
        tableBase('Guest locks',
                  'Guests whose configuration is currently locked, for example while a backup, migration or snapshot runs. Empty when nothing is running.',
                  [show('id', 'Guest'), rename('state', 'Lock'), hide('Value')],
                  [{ id: 'organize', options: { indexByName: { id: 0, state: 1 } } }],
                  [tableTarget('pve_lock_state{%s} == 1' % commonSelector)]);

      local guestCpuPanel =
        timeSeriesBase('Guest CPU usage',
                       [promTarget('(pve_cpu_usage_ratio{%s} / pve_cpu_usage_limit{%s} * on(id) group_left(name, type) pve_guest_info{%s}) * 100' % [guestSelector, guestSelector, commonSelector], '{{name}} ({{type}})')],
                       labelY1='CPU',
                       unit='percent',
                       decimals=1,
                       min=0);

      local guestMemoryPanel =
        timeSeriesBase('Guest memory usage',
                       [promTarget('(pve_memory_usage_bytes{%s} / pve_memory_size_bytes{%s} * on(id) group_left(name, type) pve_guest_info{%s}) * 100' % [guestSelector, guestSelector, commonSelector], '{{name}} ({{type}})')],
                       labelY1='Memory',
                       unit='percent',
                       decimals=1,
                       min=0,
                       max=100);

      local guestNetworkPanel =
        timeSeriesBase('Guest network I/O',
                       [
                         promTarget('rate(pve_network_receive_bytes_total{%s}[$__rate_interval]) * on(id) group_left(name, type) pve_guest_info{%s}' % [guestSelector, commonSelector], '{{name}} received'),
                         promTarget('rate(pve_network_transmit_bytes_total{%s}[$__rate_interval]) * on(id) group_left(name, type) pve_guest_info{%s}' % [guestSelector, commonSelector], '{{name}} sent'),
                       ],
                       labelY1='Throughput',
                       unit='Bps',
                       min=0);

      local guestDiskPanel =
        timeSeriesBase('Guest disk I/O',
                       [
                         promTarget('rate(pve_disk_read_bytes_total{%s}[$__rate_interval]) * on(id) group_left(name, type) pve_guest_info{%s}' % [guestSelector, commonSelector], '{{name}} read'),
                         promTarget('rate(pve_disk_written_bytes_total{%s}[$__rate_interval]) * on(id) group_left(name, type) pve_guest_info{%s}' % [guestSelector, commonSelector], '{{name}} written'),
                       ],
                       labelY1='Throughput',
                       unit='Bps',
                       min=0);

      local haStatePanel =
        tableBase('HA state',
                  'High availability state of cluster nodes and of the guests managed by HA. Empty when HA is not configured, since no state is active then.',
                  [
                    show('id', 'Resource'),
                    rename('state', 'State'),
                    hide('Value'),
                  ],
                  [{ id: 'organize', options: { indexByName: { id: 0, state: 1 } } }],
                  [tableTarget('pve_ha_state{%s} == 1' % commonSelector)]);

      local subscriptionPanel =
        tableBase('Subscription',
                  'Proxmox subscription per node: the active status, the support level and the renewal date.',
                  [
                    rename('status', 'Status'),
                    rename('level', 'Level'),
                    hide('Value #A'),
                    hide('Value #B'),
                    valueCol('Value #C', 'Renews', 'dateTimeAsIso', 0, 180),
                  ],
                  [{ id: 'merge', options: { reducers: [] } }],
                  [
                    tableTarget('max by (id, status) (pve_subscription_status{%s} == 1)' % commonSelector),
                    tableTarget('max by (id, level) (pve_subscription_info{%s})' % commonSelector),
                    tableTarget('max by (id) (pve_subscription_next_due_timestamp_seconds{%s}) * 1000' % commonSelector),
                  ]);

      local replicationPanel =
        tableBase('Replication jobs',
                  'Storage replication jobs between nodes. Empty until a replication job is configured.',
                  [
                    rename('guest', 'Guest'),
                    rename('source', 'Source'),
                    rename('target', 'Target'),
                    rename('type', 'Type'),
                    hide('Value #A'),
                    valueCol('Value #B', 'Duration', 's', 1, 100),
                    valueCol('Value #C', 'Last sync', 'dateTimeAsIso', 0, 170),
                    valueCol('Value #D', 'Last try', 'dateTimeAsIso', 0, 170),
                    valueCol('Value #E', 'Next sync', 'dateTimeAsIso', 0, 170),
                    statusCol('Value #F', 'Failed syncs', { '0': { text: 'none' } }, [{ color: color.green, value: null }, { color: color.red, value: 1 }], 120),
                  ],
                  [{ id: 'merge', options: { reducers: [] } }],
                  [
                    tableTarget('max by (id, guest, source, target, type) (pve_replication_info{%s})' % commonSelector),
                    tableTarget('max by (id) (pve_replication_duration_seconds{%s})' % commonSelector),
                    tableTarget('max by (id) (pve_replication_last_sync_timestamp_seconds{%s}) * 1000' % commonSelector),
                    tableTarget('max by (id) (pve_replication_last_try_timestamp_seconds{%s}) * 1000' % commonSelector),
                    tableTarget('max by (id) (pve_replication_next_sync_timestamp_seconds{%s}) * 1000' % commonSelector),
                    tableTarget('max by (id) (pve_replication_failed_syncs{%s})' % commonSelector),
                  ]);

      local notBackedUpPanel =
        statBase('Guests without backup',
                 'sum(pve_not_backed_up_total{%s}) OR on() vector(-1)' % commonSelector,
                 [{ color: color.green, value: null }, { color: color.orange, value: 1 }],
                 { '-1': { text: '-' } },
                 desc='Guests not covered by any backup job.');

      // Corosync metrics come from ClusterLabs ha_cluster_exporter running on the
      // nodes. Its job label differs from the PVE exporter one and its instance
      // label holds node hostnames, while $instance on this dashboard is built
      // from pve_up (a single cluster-scoped value) — so only cluster is filtered.
      local corosyncSelector = 'cluster="$cluster"';

      local corosyncQuoratePanel =
        statBase('Corosync quorum',
                 'min(ha_cluster_corosync_quorate{%s}) OR on() vector(0)' % corosyncSelector,
                 statusSteps,
                 { '0': { text: 'No quorum', color: color.red }, '1': { text: 'Quorate', color: color.green } },
                 unit='string',
                 desc='Quorum state as reported by corosync-quorumtool on the nodes. Worst value across nodes.');

      local corosyncRingErrorsPanel =
        statBase('Corosync ring errors',
                 'max(ha_cluster_corosync_ring_errors{%s}) OR on() vector(-1)' % corosyncSelector,
                 [{ color: color.green, value: null }, { color: color.red, value: 1 }],
                 { '-1': { text: '-' } },
                 desc='Total number of faulty corosync rings. Highest value across nodes.');

      local corosyncQuorumVotesPanel =
        tableBase('Quorum votes',
                  'Cluster quorum vote counts as reported by corosync-quorumtool.',
                  [
                    rename('type', 'Type'),
                    valueCol('Value', 'Votes', 'none', 0, 100),
                  ],
                  [],
                  [tableTarget('max by (type) (ha_cluster_corosync_quorum_votes{%s})' % corosyncSelector)]);

      // Note: the per-ring metric (ha_cluster_corosync_rings) is not emitted on
      // corosync 3 with knet transport, whose corosync-cfgtool output the
      // exporter cannot parse into rings — only ring_errors is available.
      local corosyncMembersPanel =
        tableBase('Corosync members',
                  'Member nodes and the votes each contributes to the quorum.',
                  [
                    rename('node', 'Node'),
                    rename('node_id', 'Node ID'),
                    valueCol('Value', 'Votes', 'none', 0, 100),
                  ],
                  [],
                  [tableTarget('max by (node, node_id) (ha_cluster_corosync_member_votes{%s})' % corosyncSelector)]);

      local panels = [
        row.new('Cluster') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        quorumPanel { gridPos: { x: 0, y: 1, w: 4, h: 4 } },
        nodesOnlinePanel { gridPos: { x: 4, y: 1, w: 3, h: 4 } },
        nodesTotalPanel { gridPos: { x: 7, y: 1, w: 3, h: 4 } },
        versionPanel { gridPos: { x: 10, y: 1, w: 4, h: 4 } },
        clusterStoragePanel { gridPos: { x: 14, y: 1, w: 4, h: 4 } },
        guestsRunningPanel { gridPos: { x: 18, y: 1, w: 3, h: 4 } },
        guestsTotalPanel { gridPos: { x: 21, y: 1, w: 3, h: 4 } },
        row.new('Nodes') + { gridPos: { x: 0, y: 5, w: 24, h: 1 } },
        nodesTablePanel { gridPos: { x: 0, y: 6, w: 24, h: 7 } },
        nodeCpuPanel { gridPos: { x: 0, y: 13, w: 8, h: 7 } },
        nodeMemoryPanel { gridPos: { x: 8, y: 13, w: 8, h: 7 } },
        nodeDiskPanel { gridPos: { x: 16, y: 13, w: 8, h: 7 } },
        row.new('Storages') + { gridPos: { x: 0, y: 20, w: 24, h: 1 } },
        storageTablePanel { gridPos: { x: 0, y: 21, w: 24, h: 8 } },
        storageUsagePanel { gridPos: { x: 0, y: 29, w: 24, h: 7 } },
        row.new('Guests') + { gridPos: { x: 0, y: 36, w: 24, h: 1 } },
        guestsTablePanel { gridPos: { x: 0, y: 37, w: 24, h: 7 } },
        guestCpuPanel { gridPos: { x: 0, y: 44, w: 12, h: 7 } },
        guestMemoryPanel { gridPos: { x: 12, y: 44, w: 12, h: 7 } },
        guestNetworkPanel { gridPos: { x: 0, y: 51, w: 12, h: 7 } },
        guestDiskPanel { gridPos: { x: 12, y: 51, w: 12, h: 7 } },
        guestLocksPanel { gridPos: { x: 0, y: 58, w: 24, h: 6 } },
        row.new('Replication') + { gridPos: { x: 0, y: 64, w: 24, h: 1 } },
        replicationPanel { gridPos: { x: 0, y: 65, w: 24, h: 7 } },
        row.new('Operations') + { gridPos: { x: 0, y: 72, w: 24, h: 1 } },
        haStatePanel { gridPos: { x: 0, y: 73, w: 8, h: 7 } },
        subscriptionPanel { gridPos: { x: 8, y: 73, w: 12, h: 7 } },
        notBackedUpPanel { gridPos: { x: 20, y: 73, w: 4, h: 7 } },
        row.new('Corosync') + { gridPos: { x: 0, y: 80, w: 24, h: 1 } },
        corosyncQuoratePanel { gridPos: { x: 0, y: 81, w: 4, h: 4 } },
        corosyncRingErrorsPanel { gridPos: { x: 4, y: 81, w: 4, h: 4 } },
        corosyncQuorumVotesPanel { gridPos: { x: 8, y: 81, w: 16, h: 6 } },
        corosyncMembersPanel { gridPos: { x: 0, y: 87, w: 24, h: 7 } },
      ];

      dashboard.new('Proxmox VE Overview')
      + dashboard.withUid($._config.grafanaDashboards.ids.proxmox)
      + dashboard.withLinks([
        dashboard.link.link.withTitle('Proxmox Nodes (OS & disks)')
        + dashboard.link.link.withType('link')
        + dashboard.link.link.withUrl('/d/%s?var-datasource=$datasource&var-cluster=$cluster' % $._config.grafanaDashboards.ids.proxmoxNode)
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
        $.grafanaTemplates.clusterTemplate('label_values(pve_up, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(pve_up{cluster="$cluster"}, job)'),
        $.grafanaTemplates.instanceTemplate('label_values(pve_up{cluster="$cluster", job=~"$job"}, instance)'),
      ])
      + dashboard.withPanels(panels),
  },
}
