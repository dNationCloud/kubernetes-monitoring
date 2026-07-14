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

/* Host alert overview dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local table = grafana.panel.table;
local fieldOverride = grafana.panel.table.fieldOverride;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    local cfg = $._config.grafanaDashboards,
    local color = cfg.color,

    local rename(name, alias) =
      fieldOverride.byName.new(name)
      + fieldOverride.byName.withProperty('displayName', alias),

    local tableTarget(expr) = prometheus.withExpr(expr) + prometheus.withFormat('table') + prometheus.withInstant(true),

    local severityRowColor =
      fieldOverride.byName.new('severity')
      + fieldOverride.byName.withProperty('mappings', [{ type: 'value', options: { warning: { color: color.orange, index: 0 }, critical: { color: color.red, index: 1 } } }])
      + fieldOverride.byName.withProperty('custom.cellOptions', { type: 'color-background', mode: 'basic', applyToRow: true }),

    local tableBase(warnExpr, critExpr, extraCols, transformations) =
      table.new('Alerts Info')
      + table.queryOptions.withDatasource('prometheus', '$datasource')
      + { fieldConfig+: { defaults+: { custom+: { minWidth: 150 } } } }
      + table.standardOptions.withOverrides(
        [rename('Time', 'Starts At'), severityRowColor]
        + extraCols
      )
      + table.queryOptions.withTransformations(transformations)
      + table.queryOptions.withTargets([tableTarget(warnExpr), tableTarget(critExpr)]),

    local alertDash(name, uid, tags, variables, table) =
      dashboard.new(name)
      + dashboard.withUid(uid)
      + dashboard.withTags(tags)
      + dashboard.withEditable(cfg.editable)
      + dashboard.withRefresh(cfg.refresh)
      + dashboard.time.withFrom(cfg.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables(variables)
      + dashboard.withPanels([
        row.new('Alerts') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        table { gridPos: { x: 0, y: 1, w: 24, h: 22 } },
      ]),

    local organize(indexByName) = { id: 'organize', options: { excludeByName: { __name__: true, prometheus: true, 'Value #A': true, 'Value #B': true }, indexByName: indexByName } },
    'alert-host-overview':
      alertDash('AlertHost', cfg.ids.alertHostOverview, cfg.tags.k8sOverview, [
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.alertManagerTemplate(),
        $.grafanaTemplates.alertGroupTemplate('label_values(ALERTS, alertgroup)'),
        $.grafanaTemplates.severityTemplate('label_values(ALERTS, severity)'),
        $.grafanaTemplates.jobTemplate('label_values(ALERTS, job)', hide='variable'),
      ], tableBase(
        'ALERTS{job=~"$job", alertname!="Watchdog", alertstate=~"firing", severity="warning", severity=~"$severity", alertgroup=~"$alertgroup"}',
        'ALERTS{job=~"$job", alertname!="Watchdog", alertstate=~"firing", severity="critical", severity=~"$severity", alertgroup=~"$alertgroup"}',
        [rename('alertname', 'Alertname'), rename('job', 'Job'), rename('nodename', 'Node')],
        [organize({ Time: 0, severity: 1, nodename: 2, alertname: 3, job: 4, alertstate: 4, alertgroup: 5 })]
      )),
  },
}
