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

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local statPanel = grafana.statPanel;
local row = grafana.row;
local link = grafana.link;
local text = grafana.text;

{
  grafanaDashboards+::
    local hostDashboard(hostUid, dashboardName, alertJobs, hostTemplates, hostApps=[], jobName=null) = {
      local monitoringLink =
        link.dashboards(
          title='Monitoring',
          tags=[],
          url='/d/%s' % $._config.grafanaDashboards.ids.monitoring,
          type='link',
        ),

      local dNationLink =
        link.dashboards(
          title='dNation - Making Cloud Easy',
          tags=[],
          icon='cloud',
          url='https://www.dNation.cloud/',
          type='link',
          targetBlank=true,
        ),

      local alertPanel(title, expr) =
        statPanel.new(
          title=title,
          datasource='$datasource',
          graphMode='none',
          colorMode='background',
          reducerFunction='last',
        )
        .addTarget({ type: 'single', expr: expr }),

      local criticalPanel =
        alertPanel(
          title='Critical',
          expr='sum(ALERTS{alertname!="Watchdog", severity="critical", alertgroup=~"%s|%s", job=~"%s"}) OR on() vector(0)' % [$._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp, std.join('|', alertJobs)],
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&var-job=%s&var-alertgroup=%s&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertHostOverview, std.join('&var-job=', alertJobs), $._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.commonThresholds.criticalPanel)),

      local warningPanel =
        alertPanel(
          title='Warning',
          expr='sum(ALERTS{alertname!="Watchdog", severity="warning", alertgroup=~"%s|%s", job=~"%s"}) OR on() vector(0)' % [$._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp, std.join('|', alertJobs)],
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&var-job=%s&var-alertgroup=%s&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertHostOverview, std.join('&var-job=', alertJobs), $._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.commonThresholds.warningPanel)),

      local hostStatsPanels = [
        statPanel.new(
          title=tpl.panel.title,
          description='%s\n\nHost monitoring template: _%s_' % [tpl.panel.description, tpl.templateName],
          datasource=tpl.panel.datasource,
          colorMode=tpl.panel.colorMode,
          graphMode=tpl.panel.graphMode,
          unit=tpl.panel.unit,
          decimals=tpl.panel.decimals,
        )
        .addTarget(prometheus.target(tpl.panel.expr))
        .addMappings(tpl.panel.mappings)
        .addDataLinks($.updateDataLinksCommonArgs(tpl.panel.dataLinks))
        .addThresholds($.grafanaThresholds(tpl.panel.thresholds))
        {
          gridPos: {
            x: tpl.panel.gridPos.x,
            y: tpl.panel.gridPos.y,
            w: tpl.panel.gridPos.w,
            h: tpl.panel.gridPos.h,
          },
        }
        for tpl in hostTemplates
        if (std.objectHas(tpl, 'panel') && tpl.panel != {})
      ],

      local hostAppStatsPanels(index, app) = [
        local tpl = template.item;
        local tplIndex = template.index;

        local appGridX =
          if std.type(tpl.panel.gridPos.x) == 'number' then
            tpl.panel.gridPos.x
          else
            (index + tplIndex) * tpl.panel.gridPos.w;

        local appGridY =
          if std.type(tpl.panel.gridPos.y) == 'number' then
            tpl.panel.gridPos.y
          else
            12;  // `12` -> init Y position in application row;

        local datalinks =
          if std.length(tpl.panel.dataLinks) > 0 then
            [
              dataLink {
                url: dataLink.url % { job: app.jobName },
              }
              for dataLink in tpl.panel.dataLinks
            ]
          else if std.objectHas($._config.grafanaDashboards.ids, tpl.templateName) then
            [{ title: 'Detail', url: '/d/%s?var-job=%s&%s' % [$._config.grafanaDashboards.ids[tpl.templateName], app.jobName, $._config.grafanaDashboards.dataLinkCommonArgs] }]
          else
            [];

        statPanel.new(
          title='%s %s' % [tpl.templateName, app.name],
          description='%s\n\nApplication monitoring template: _%s_' % [app.description, tpl.templateName],
          datasource=tpl.panel.datasource,
          colorMode=tpl.panel.colorMode,
          graphMode=tpl.panel.graphMode,
          unit=tpl.panel.unit,
          decimals=tpl.panel.decimals,
        )
        .addTarget(prometheus.target(tpl.panel.expr % { job: 'job=~"%s"' % app.jobName }))
        .addMappings(tpl.panel.mappings)
        .addDataLinks($.updateDataLinksCommonArgs(datalinks))
        .addThresholds($.grafanaThresholds(tpl.panel.thresholds))
        {
          gridPos: {
            x: appGridX,
            y: appGridY,
            w: tpl.panel.gridPos.w,
            h: tpl.panel.gridPos.h,
          },
        }
        for template in $.zipWithIndex(app.templates)
      ],

      local applicationPanels(apps) =
        if std.length(apps) > 0 then
          [
            row.new('Applications') { gridPos: { x: 0, y: 11, w: 24, h: 1 } },
          ] +
          std.flattenArrays([
            hostAppStatsPanels(app.index, app.item)
            for app in $.zipWithIndex(apps)
          ])
        else
          [],

      dashboard:
        dashboard.new(
          dashboardName,
          editable=$._config.grafanaDashboards.editable,
          graphTooltip=$._config.grafanaDashboards.tooltip,
          refresh=$._config.grafanaDashboards.refresh,
          time_from=$._config.grafanaDashboards.time_from,
          tags=$._config.grafanaDashboards.tags.k8sHostsMain,
          uid=hostUid,
        )
        .addLinks(
          [
            monitoringLink,
            dNationLink,
          ]
        )
        .addTemplates([
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.alertManagerTemplate(),
          $.grafanaTemplates.jobTemplate('label_values(node_uname_info{pod=~""}, job)', hide='variable', current=jobName, includeAll=false, multi=false),
          $.grafanaTemplates.clusterTemplate('label_values(node_uname_info{job=~"$job"}, cluster)'),
        ])
        .addPanels(
          [
            row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
            criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
            warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
            row.new('Host') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
            text.new('CPU') { gridPos: { x: 0, y: 5, w: 6, h: 1 } },
            text.new('RAM') { gridPos: { x: 6, y: 5, w: 6, h: 1 } },
            text.new('Disk') { gridPos: { x: 12, y: 5, w: 6, h: 1 } },
            text.new('Network') { gridPos: { x: 18, y: 5, w: 6, h: 1 } },
          ] + hostStatsPanels + applicationPanels(hostApps)
        ),
    };
    if $.isHostMonitoring() then
      {
        ['host-monitoring-%s' % host.name]:
          hostDashboard(
            $.getCustomUid([$._config.grafanaDashboards.ids.hostMonitoring, host.name]),
            $.getCustomName(['Host Monitoring', host.name]),
            $.getAlertJobs(host),
            $.getTemplates($._config.templates.L1.host, host),
            $.getApps($._config.templates.L1.hostApps, host),
            host.jobName,
          ).dashboard
        for host in $._config.hostMonitoring.hosts
        if (std.objectHas(host, 'apps') || !$.hasDefaultTemplates(host, $._config.templates.L1.k8s))
      } +
      if $.isAnyDefault($._config.hostMonitoring.hosts, $._config.templates.L1.host) then
        {
          'host-monitoring': hostDashboard($._config.grafanaDashboards.ids.hostMonitoring, 'Host Monitoring', ['$job'], $.getTemplates($._config.templates.L1.host)).dashboard,
        }
      else
        {}
    else
      {},
}
