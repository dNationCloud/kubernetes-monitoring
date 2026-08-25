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

/* Host main dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local statPanel = grafana.panel.stat;
local row = grafana.panel.row;
local text = grafana.panel.text;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+::
    local hostDashboard(hostUid, dashboardName, alertJobs, hostTemplates, hostApps=[], jobName=null) = {
      local monitoringLink =
        dashboard.link.link.new('Monitoring', '/d/%s' % $._config.grafanaDashboards.ids.monitoring),

      local dNationLink =
        dashboard.link.link.new('dNation - Making Cloud Easy', 'https://www.dNation.cloud/')
        + dashboard.link.link.withIcon('cloud')
        + dashboard.link.link.options.withTargetBlank(true),

      local statAlert(title, expr) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.options.withGraphMode('none') + statPanel.options.withColorMode('background') + statPanel.options.reduceOptions.withCalcs(['last'])
        + statPanel.queryOptions.withTargets([{ type: 'single', expr: expr, refId: 'A' }]),

      local criticalPanel =
        statAlert('Critical', 'sum(ALERTS{alertname!="Watchdog", severity="critical", alertgroup=~"%s|%s", job=~"%s"}) OR on() vector(0)' % [$._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp, std.join('|', alertJobs)])
        + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs([{ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&var-job=%s&var-alertgroup=%s&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertHostOverview, std.join('&var-job=', alertJobs), $._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp, $._config.grafanaDashboards.dataLinkCommonArgs] }]))
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds($._config.templates.commonThresholds.criticalPanel)),

      local warningPanel =
        statAlert('Warning', 'sum(ALERTS{alertname!="Watchdog", severity="warning", alertgroup=~"%s|%s", job=~"%s"}) OR on() vector(0)' % [$._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp, std.join('|', alertJobs)])
        + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs([{ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&var-job=%s&var-alertgroup=%s&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertHostOverview, std.join('&var-job=', alertJobs), $._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp, $._config.grafanaDashboards.dataLinkCommonArgs] }]))
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds($._config.templates.commonThresholds.warningPanel)),

      local statBase(title, p, desc) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource') + statPanel.panelOptions.withDescription(desc)
        + (if std.objectHas(p, 'colorMode') then statPanel.options.withColorMode(p.colorMode) else {})
        + (if std.objectHas(p, 'graphMode') then statPanel.options.withGraphMode(p.graphMode) else {})
        + (if std.objectHas(p, 'unit') then statPanel.standardOptions.withUnit(p.unit) else {})
        + (if std.objectHas(p, 'decimals') && p.decimals != null then statPanel.standardOptions.withDecimals(p.decimals) else {}),

      local hostStatsPanels = [
        statBase(tpl.panel.title, tpl.panel, '%s\n\nHost monitoring template: _%s_' % [tpl.panel.description, tpl.templateName])
        + statPanel.queryOptions.withTargets([prometheus.withExpr(tpl.panel.expr)])
        + statPanel.standardOptions.withMappings(tpl.panel.mappings)
        + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs(tpl.panel.dataLinks))
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds(tpl.panel.thresholds))
        + { gridPos: { x: tpl.panel.gridPos.x, y: tpl.panel.gridPos.y, w: tpl.panel.gridPos.w, h: tpl.panel.gridPos.h } }
        for tpl in hostTemplates
        if (std.objectHas(tpl, 'panel') && tpl.panel != {})
      ],

      local hostAppStatsPanels(index, app) = [
        local tpl = template.item;
        local appGridX = if std.type(tpl.panel.gridPos.x) == 'number' then tpl.panel.gridPos.x else (index + template.index) * tpl.panel.gridPos.w;
        local appGridY = if std.type(tpl.panel.gridPos.y) == 'number' then tpl.panel.gridPos.y else 13;

        local datalinks =
          if std.length(tpl.panel.dataLinks) > 0 then [dataLink { url: dataLink.url % { job: app.jobName } } for dataLink in tpl.panel.dataLinks]
          else if std.objectHas($._config.grafanaDashboards.ids, tpl.templateName) then [{ title: 'Detail', url: '/d/%s?var-job=%s&%s' % [$._config.grafanaDashboards.ids[tpl.templateName], app.jobName, $._config.grafanaDashboards.dataLinkCommonArgs] }]
          else [];
        statBase('%s %s' % [tpl.templateName, app.name], tpl.panel, '%s\n\nApplication monitoring template: _%s_' % [app.description, tpl.templateName])
        + statPanel.queryOptions.withTargets([prometheus.withExpr(tpl.panel.expr % { job: 'job=~"%s"' % app.jobName })])
        + statPanel.standardOptions.withMappings(tpl.panel.mappings)
        + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs(datalinks))
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds(tpl.panel.thresholds))
        + { gridPos: { x: appGridX, y: appGridY, w: tpl.panel.gridPos.w, h: tpl.panel.gridPos.h } }
        for template in $.zipWithIndex(app.templates)
      ],

      local applicationPanels(apps) =
        if std.length(apps) > 0 then
          [row.new('Applications') + { gridPos: { x: 0, y: 12, w: 24, h: 1 } }]
          + std.flattenArrays([hostAppStatsPanels(app.index, app.item) for app in $.zipWithIndex(apps)])
        else [],

      local txt(t, x, y, w) = text.new(t) + { gridPos: { x: x, y: y, w: w, h: 1 } },

      dashboard:
        dashboard.new(dashboardName)
        + dashboard.withUid(hostUid) + dashboard.withTags($._config.grafanaDashboards.tags.k8sHostsMain)
        + dashboard.withEditable($._config.grafanaDashboards.editable) + dashboard.withRefresh($._config.grafanaDashboards.refresh)
        + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
        + $._config.grafanaDashboards.tooltip
        + dashboard.withTimezone('browser')
        + dashboard.withLinks([monitoringLink, dNationLink])
        + dashboard.withVariables([
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.alertManagerTemplate(),
          $.grafanaTemplates.jobTemplate('label_values(node_uname_info{pod=~""}, job)', hide='variable', current=jobName, includeAll=false, multi=false),
          $.grafanaTemplates.clusterTemplate('label_values(node_uname_info{job=~"$job"}, cluster)'),
        ])
        + dashboard.withPanels([
          row.new('Alerts') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
          warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
          row.new('Host') + { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
          txt('CPU', 0, 5, 6),
          txt('RAM', 6, 5, 6),
          txt('Disk', 12, 5, 6),
          txt('Network', 18, 5, 6),
        ] + hostStatsPanels + applicationPanels(hostApps)),
    };

    if $.isHostMonitoring() then
      {
        ['host-monitoring-%s' % host.name]:
          hostDashboard($.getCustomUid([$._config.grafanaDashboards.ids.hostMonitoring, host.name]), $.getCustomName(['Host Monitoring', host.name]), $.getAlertJobs(host), $.getTemplates($._config.templates.L1.host, host), $.getApps($._config.templates.L1.hostApps, host), host.jobName).dashboard
        for host in $._config.hostMonitoring.hosts
        if (std.objectHas(host, 'apps') || !$.hasDefaultTemplates(host, $._config.templates.L1.k8s))
      } +
      if $.isAnyDefault($._config.hostMonitoring.hosts, $._config.templates.L1.host) then
        { 'host-monitoring': hostDashboard($._config.grafanaDashboards.ids.hostMonitoring, 'Host Monitoring', ['$job'], $.getTemplates($._config.templates.L1.host)).dashboard }
      else {}
    else {},
}
