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
  Rule generator of Proxmox alerting.

  An alert definition (nodes.libsonnet, ceph.libsonnet) looks like:
    nodeDown: {
      name: 'NodeDown',
      message: 'Node {{ $labels.id }} is down',
      expr: {
        absolute: 'max by (cluster, id) (pve_up{id=~"node/.+", %(selector)s})',
        percent: '...',   // optional, used when type is 'percent'
      },
    }
  `%(selector)s` must be put into every metric selector of the expression;
  the generator fills it with the cluster matcher.
*/

{
  // std.get is missing in older jsonnet versions (the translator may use one)
  get(o, key, default):: if std.objectHas(o, key) then o[key] else default,

  // A threshold is active unless it is null or false. false is needed in Helm
  // values, because Helm drops keys set to null before they reach jsonnet.
  isSet(settings, key):: $.get(settings, key, null) != null && $.get(settings, key, null) != false,

  // Same model as the Kubernetes thresholds (templates.libsonnet commonThresholds):
  // one operator (direction) and a warning and a critical level.
  levels:: ['critical', 'warning'],
  operators:: ['<', '<=', '>', '>=', '==', '!='],

  // Rules of one alert with one settings object and one cluster selector.
  //
  // The expression is formatted with the alert settings plus:
  //   %(selector)s   cluster matcher (+ the source selector of the definition)
  // and, when cfg.clusterScope is set (off by default), limited to clusters
  // that have that metric. Proxmox series are selected by the platform label in
  // cfg.selectors instead, so only they are fetched.
  alertRules(cfg, key, def, settings, selector)::
    local type = $.get(settings, 'type', 'absolute');
    local op =
      if std.member($.operators, $.get(settings, 'operator', null)) then settings.operator
      else error 'Proxmox alert %s: operator must be one of %s' % [key, std.join(' ', $.operators)];
    local source = $.get(def, 'source', null);
    local fullSelector =
      if source != null && cfg.selectors[source] != '' then selector + ', ' + cfg.selectors[source] else selector;
    local raw =
      if std.objectHas(def.expr, type) then std.rstripChars(def.expr[type] % (settings { selector: fullSelector }), '\n')
      else error 'Proxmox alert %s does not support threshold type %s' % [key, type];
    // A threshold is a number or a PromQL expression returning one value per
    // cluster (e.g. 'ceil(count by (cluster) (ceph_mon_quorum_status{%(selector)s}) / 2)').
    local threshold(level) =
      if std.isString(settings[level]) then '(%s)' % (settings[level] % (settings { selector: fullSelector }))
      else std.toString(settings[level]);
    local expr =
      if $.isSet(cfg, 'clusterScope') then '((%s) and on (cluster) max by (cluster) (%s{%s}))' % [raw, cfg.clusterScope, selector]
      else '(%s)' % raw;
    [
      {
        alert: cfg.alertNamePrefix + def.name,
        expr: '%s %s %s' % [expr, op, threshold(level)],
        'for': $.get(settings, 'for', '5m'),
        labels: {
          severity: level,
          alertgroup: cfg.alertGroup,
        } + cfg.commonLabels + $.get(settings, 'labels', {}),
        annotations: {
          // one message, or one per threshold type (the value has a different unit)
          message: if std.isObject(def.message) then def.message[type] else def.message,
          link: '%s?var-cluster={{ $labels.cluster }}' % cfg.dashboardUid,
        },
      }
      for level in $.levels
      if $.isSet(settings, level)
    ],

  // Rules of one alert: the global rule for all clusters without an override,
  // plus one rule per cluster that overrides this alert.
  rulesForAlert(cfg, key, def)::
    local base = $.get(cfg.alerts, key, {});
    local overridden = [
      c
      for c in std.objectFields(cfg.clusters)
      if std.objectHas($.get(cfg.clusters[c], 'alerts', {}), key)
    ];
    local defaultSelector =
      if std.length(overridden) == 0 then 'cluster=~".+"'
      else 'cluster!~"%s"' % std.join('|', overridden);
    (if $.get(base, 'enabled', false) then $.alertRules(cfg, key, def, base, defaultSelector) else [])
    + std.flattenArrays([
      local merged = std.mergePatch(base, cfg.clusters[c].alerts[key]);
      if $.get(merged, 'enabled', false) then $.alertRules(cfg, key, def, merged, 'cluster="%s"' % c) else []
      for c in overridden
    ]),

  // All rules of a set of alert definitions.
  rules(cfg, defs)::
    std.flattenArrays([$.rulesForAlert(cfg, key, defs[key]) for key in std.objectFields(defs)]),
}
