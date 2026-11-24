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
  Ceph alert definitions for Proxmox clusters (thresholds are in config.libsonnet).
  Metrics come from the Ceph mgr prometheus module.
*/

local quorum = {
  absolute: 'sum by (cluster) (ceph_mon_quorum_status{%(selector)s})',
  percent: '100 * sum by (cluster) (ceph_mon_quorum_status{%(selector)s}) / count by (cluster) (ceph_mon_quorum_status{%(selector)s})',
};

{
  cephHealth: {
    name: 'CephHealth',
    source: 'ceph',
    message: 'Ceph in cluster {{ $labels.cluster }} is not healthy (ceph_health_status {{ $value }}: 1 = HEALTH_WARN, 2 = HEALTH_ERR).',
    expr: {
      absolute: 'max by (cluster) (ceph_health_status{%(selector)s})',
    },
  },

  cephOsdDown: {
    name: 'CephOsdDown',
    source: 'ceph',
    message: 'Ceph {{ $labels.ceph_daemon }} in cluster {{ $labels.cluster }} is down.',
    expr: {
      absolute: 'max by (cluster, ceph_daemon) (ceph_osd_up{%(selector)s})',
    },
  },

  cephMonQuorumLow: {
    name: 'CephMonQuorumLow',
    source: 'ceph',
    message: {
      absolute: 'Ceph in cluster {{ $labels.cluster }} has low monitor quorum ({{ $value }} monitors in quorum).',
      percent: 'Ceph in cluster {{ $labels.cluster }} has low monitor quorum ({{ printf "%.0f" $value }} % of monitors in quorum).',
    },
    expr: quorum,
  },

  cephMonQuorumLowLong: {
    name: 'CephMonQuorumLowLong',
    source: 'ceph',
    message: {
      absolute: 'Ceph in cluster {{ $labels.cluster }} has had low monitor quorum for a long time, self healing failed ({{ $value }} monitors in quorum).',
      percent: 'Ceph in cluster {{ $labels.cluster }} has had low monitor quorum for a long time, self healing failed ({{ printf "%.0f" $value }} % of monitors in quorum).',
    },
    expr: quorum,
  },

  cephMonQuorumLost: {
    name: 'CephMonQuorumLost',
    source: 'ceph',
    message: {
      absolute: 'Ceph monitors in cluster {{ $labels.cluster }} lost quorum ({{ $value }} monitors in quorum).',
      percent: 'Ceph monitors in cluster {{ $labels.cluster }} lost quorum ({{ printf "%.0f" $value }} % of monitors in quorum).',
    },
    expr: quorum,
  },
}
