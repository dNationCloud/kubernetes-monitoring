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
  Proxmox node alert definitions (thresholds are in config.libsonnet).

  Every expression returns one value per object; the generator appends the
  comparison with the threshold. Alloy scrapes every 60 s, so rate windows are
  at least 3m (two samples are needed even when one scrape is late).
*/

{
  nodeDown: {
    name: 'NodeDown',
    source: 'pve',
    message: 'Proxmox node {{ $labels.id }} in cluster {{ $labels.cluster }} is down.',
    expr: {
      // pve_up comes from the PVE API, so it reports a node as down even when
      // the agents on that node are gone. max by() guards against duplicates.
      absolute: 'max by (cluster, id) (pve_up{id=~"node/.+", %(selector)s})',
    },
  },

  networkIo: {
    name: 'NetworkIoZero',
    source: 'node',
    message: 'No network I/O on {{ $labels.device }} of node {{ $labels.instance }} in cluster {{ $labels.cluster }} ({{ printf "%.0f" $value }} B/s or no data).',
    expr: {
      // Current traffic, or 0 for a link that reported during the last hour
      // (until 10 minutes ago) but has no data now.
      absolute: |||
        (
          sum by (cluster, instance, device) (
            rate(node_network_receive_bytes_total{device=~"%(devices)s", device!~"%(devicesExclude)s", %(selector)s}[3m])
            + rate(node_network_transmit_bytes_total{device=~"%(devices)s", device!~"%(devicesExclude)s", %(selector)s}[3m])
          )
          or
          0 * (
            max by (cluster, instance, device) (max_over_time(node_network_receive_bytes_total{device=~"%(devices)s", device!~"%(devicesExclude)s", %(selector)s}[1h] offset 10m))
            unless
            max by (cluster, instance, device) (node_network_receive_bytes_total{device=~"%(devices)s", device!~"%(devicesExclude)s", %(selector)s})
          )
        )
      |||,
    },
  },

  smartFailure: {
    name: 'DiskSmartFailure',
    source: 'smart',
    message: 'SMART health check failed for disk {{ $labels.device }} of node {{ $labels.instance }} in cluster {{ $labels.cluster }}.',
    expr: {
      absolute: 'max by (cluster, instance, device) (smartctl_device_smart_status{%(selector)s})',
    },
  },

  filesystemUsage: {
    name: 'FilesystemUsage',
    source: 'node',
    message: {
      percent: 'Filesystem {{ $labels.mountpoint }} on node {{ $labels.instance }} in cluster {{ $labels.cluster }} is {{ printf "%.1f" $value }} % full.',
      absolute: 'Filesystem {{ $labels.mountpoint }} on node {{ $labels.instance }} in cluster {{ $labels.cluster }} has {{ humanize1024 $value }}B free.',
    },
    expr: {
      percent: |||
        max by (cluster, instance, mountpoint) (
          100 * (1 - node_filesystem_avail_bytes{mountpoint=~"%(mountpoints)s", fstype!~"%(fstypesExclude)s", %(selector)s}
                   / node_filesystem_size_bytes{mountpoint=~"%(mountpoints)s", fstype!~"%(fstypesExclude)s", %(selector)s})
        )
      |||,
      absolute: 'max by (cluster, instance, mountpoint) (node_filesystem_avail_bytes{mountpoint=~"%(mountpoints)s", fstype!~"%(fstypesExclude)s", %(selector)s})',
    },
  },

  memoryAvailable: {
    name: 'MemoryAvailable',
    source: 'node',
    message: {
      percent: 'Node {{ $labels.instance }} in cluster {{ $labels.cluster }} has {{ printf "%.1f" $value }} % of memory available.',
      absolute: 'Node {{ $labels.instance }} in cluster {{ $labels.cluster }} has {{ humanize1024 $value }}B of memory available.',
    },
    expr: {
      percent: 'max by (cluster, instance) (100 * node_memory_MemAvailable_bytes{%(selector)s} / node_memory_MemTotal_bytes{%(selector)s})',
      absolute: 'max by (cluster, instance) (node_memory_MemAvailable_bytes{%(selector)s})',
    },
  },

  cpuUtilization: {
    name: 'CpuUtilization',
    source: 'node',
    message: 'CPU utilization of node {{ $labels.instance }} in cluster {{ $labels.cluster }}: {{ printf "%.1f" $value }} %.',
    expr: {
      percent: '100 * (1 - avg by (cluster, instance) (rate(node_cpu_seconds_total{mode="idle", %(selector)s}[3m])))',
    },
  },

  nodeOomKill: {
    name: 'NodeOomKill',
    source: 'node',
    message: 'OOM killer on node {{ $labels.instance }} in cluster {{ $labels.cluster }} killed {{ $value }} process(es) in the last 5 minutes.',
    expr: {
      absolute: 'round(max by (cluster, instance) (increase(node_vmstat_oom_kill{%(selector)s}[5m])))',
    },
  },

  guestOomKill: {
    name: 'GuestOomKill',
    source: 'pve',
    message: 'OOM killer of the host killed {{ $value }} process(es) of guest {{ $labels.id }} in cluster {{ $labels.cluster }} in the last 5 minutes.',
    expr: {
      // summed by id: a migrated guest has counts on two nodes
      absolute: 'round(sum by (cluster, id) (increase(pve_guest_oom_kills_total{%(selector)s}[5m])))',
    },
  },
}
