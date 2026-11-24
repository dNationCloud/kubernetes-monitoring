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
  Proxmox alerting: generates Prometheus rules for Proxmox VE clusters.

  Kept apart from the Kubernetes alerting (rules.jsonnet, templates.libsonnet):
  own configuration (rules/proxmox/config.libsonnet, Helm values `proxmoxAlerting`),
  own ConfigMap and own PrometheusRule label, so the rules can be evaluated by
  a different component (e.g. Thanos Ruler) than the Kubernetes rules.
*/

local ceph = import 'rules/proxmox/ceph.libsonnet';
local defaults = import 'rules/proxmox/config.libsonnet';
local lib = import 'rules/proxmox/lib.libsonnet';
local nodes = import 'rules/proxmox/nodes.libsonnet';

function(customConfig={})
  /**
   * Generate Proxmox prometheus rules
   *
   * @param customConfig Helm values (the `proxmoxAlerting` key is used).
   * @return one prometheus rule object per file name.
   */
  local cfg = std.mergePatch(defaults, if std.objectHas(customConfig, 'proxmoxAlerting') then customConfig.proxmoxAlerting else {});
  local sets = {
    'proxmox-nodes': nodes,
    'proxmox-ceph': ceph,
  };
  {
    ['%s.json' % name]: {
      groups: [{ name: '%s.rules' % name, rules: lib.rules(cfg, sets[name]) }],
    }
    for name in std.objectFields(sets)
    if std.length(lib.rules(cfg, sets[name])) > 0
  }
