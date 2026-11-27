/*
  Copyright 2026 The dNation Kubernetes Monitoring Authors. All Rights Reserved.
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

/*
  Default configuration of Proxmox alerting.

  Independent of the Kubernetes alerting (config.libsonnet, templates.libsonnet).
  Every value can be overridden from Helm values under `proxmoxRules`
  (JSON merge patch, RFC 7396).

  Thresholds of every alert (same model as the Kubernetes thresholds):
    type      'absolute' or 'percent' (selects the expression of the alert)
    operator  direction of the limit: '>=' / '>' (above) or '<=' / '<' (below)
    warning   warning  when value <operator> warning
    critical  critical when value <operator> critical
  warning and critical are numbers, or PromQL expressions returning one value per
  cluster (%(selector)s is replaced by the cluster selector), see the Ceph quorum alerts.
  A level set to false, null or left out generates no rule. Use false in
  Helm values: Helm drops keys set to null.

  Per cluster overrides go to `clusters.<cluster label>.alerts.<alert>`; they are
  merged onto the global alert settings for that cluster only.
*/

{
  alertNamePrefix: 'Proxmox',
  alertGroup: 'Proxmox',
  // Grafana dashboard uid used for the `link` annotation
  dashboardUid: 'proxmox',
  // labels added to every Proxmox alert
  commonLabels: {},

  // Optional: limit alerts to clusters that have this metric (e.g. 'pve_up').
  // Not needed with the platform label below, which already selects Proxmox
  // series only; the filter is applied after the series are fetched, so it
  // only adds query cost. false = off.
  clusterScope: false,

  // Selectors of the metric sources, added to every expression of that source.
  // platform="proxmox" is set by Alloy on the Proxmox nodes (external_labels of
  // prometheus.remote_write), so the rules fetch only Proxmox series and never
  // node-exporter series of Kubernetes clusters, which use the same job name.
  selectors: {
    pve: 'platform="proxmox"',
    node: 'platform="proxmox", job="node-exporter"',
    smart: 'platform="proxmox", job="smartctl-exporter"',
    ceph: 'platform="proxmox"',
  },

  alerts: {
    // Node is down according to the Proxmox API (pve_up of node/<name>)
    nodeDown: {
      enabled: true,
      type: 'absolute',
      'for': '5m',
      operator: '<=',
      critical: 0,
      labels: {},
    },
    // Network I/O (received + sent bytes/s) of a link is 0, or the link stopped
    // reporting (it reported during the last hour but has no data now).
    networkIo: {
      enabled: true,
      type: 'absolute',
      'for': '5m',
      operator: '<=',
      critical: 0,
      // links that are checked; virtual guest interfaces come and go with guests
      devices: '.+',
      devicesExclude: 'lo|tap.+|veth.+|fwbr.+|fwpr.+|fwln.+',
      labels: {},
    },
    // SMART overall health of a disk failed (smartctl_device_smart_status 0)
    smartFailure: {
      enabled: true,
      type: 'absolute',
      'for': '5m',
      operator: '<=',
      critical: 0,
      labels: {},
    },
    // Filesystem usage. percent: used %, absolute: available bytes (use operator '<=')
    filesystemUsage: {
      enabled: true,
      type: 'percent',
      'for': '5m',
      operator: '>=',
      warning: 80,
      critical: 90,
      mountpoints: '/|/var|/var/.+|/etc|/etc/.+',
      fstypesExclude: 'tmpfs|ramfs|squashfs|overlay|fuse.lxcfs',
      labels: {},
    },
    // Available memory. percent: available %, absolute: available bytes
    memoryAvailable: {
      enabled: true,
      type: 'percent',
      'for': '5m',
      operator: '<=',
      warning: 10,
      critical: 5,
      labels: {},
    },
    // CPU utilization of the whole node in %
    cpuUtilization: {
      enabled: true,
      type: 'percent',
      'for': '5m',
      operator: '>=',
      critical: 99,
      labels: {},
    },
    // Processes killed by the OOM killer of the node in the last 5 minutes
    nodeOomKill: {
      enabled: true,
      type: 'absolute',
      'for': '0m',
      operator: '>=',
      critical: 1,
      labels: {},
    },
    // Processes of a guest killed by the OOM killer of the host in the last 5 minutes
    // (pve_guest_oom_kills_total from the pve-guest-oom textfile script)
    guestOomKill: {
      enabled: true,
      type: 'absolute',
      'for': '0m',
      operator: '>=',
      warning: 1,
      labels: {},
    },

    // Ceph (mgr prometheus module) of the Proxmox cluster.
    // Overall health: 0 HEALTH_OK, 1 HEALTH_WARN, 2 HEALTH_ERR
    cephHealth: {
      enabled: true,
      type: 'absolute',
      'for': '5m',
      operator: '>=',
      warning: 1,
      critical: 2,
      labels: {},
    },
    // OSD is down (ceph_osd_up != 1)
    cephOsdDown: {
      enabled: true,
      type: 'absolute',
      'for': '10m',
      operator: '!=',
      critical: 1,
      labels: {},
    },
    // Monitors in quorum. absolute: number of mons in quorum, percent: % of mons in quorum.
    // Low quorum: only a bare majority (or less) of the mons is in quorum.
    cephMonQuorumLow: {
      enabled: true,
      type: 'absolute',
      'for': '5m',
      operator: '<=',
      warning: 'ceil(count by (cluster) (ceph_mon_quorum_status{%(selector)s}) / 2)',
      labels: {},
    },
    // Low quorum for a long time: self healing failed
    cephMonQuorumLowLong: {
      enabled: true,
      type: 'absolute',
      'for': '35m',
      operator: '<=',
      critical: 'ceil(count by (cluster) (ceph_mon_quorum_status{%(selector)s}) / 2)',
      labels: {},
    },
    // Quorum lost: half of the mons or less are in quorum
    cephMonQuorumLost: {
      enabled: true,
      type: 'absolute',
      'for': '10m',
      operator: '<=',
      critical: 'floor(count by (cluster) (ceph_mon_quorum_status{%(selector)s}) / 2)',
      labels: {},
    },
  },

  clusters: {},
}
