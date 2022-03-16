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

/* VM main dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local statPanel = grafana.statPanel;
local row = grafana.row;
local link = grafana.link;
local text = grafana.text;

{
  grafanaDashboards+::
    local vmDashboard(vmUid, dashboardName, alertJobs, vmTemplates, vmApps=[]) = {
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
        )
        .addTarget({ type: 'single', expr: expr }),

      local criticalPanel =
        alertPanel(
          title='Critical',
          expr='ALERTS{alertname!="Watchdog", severity="critical", alertgroup=~"%s|%s", job=~"%s"} OR on() vector(0)' % [$._config.prometheusRules.alertGroupClusterVM, $._config.prometheusRules.alertGroupClusterVMApp, std.join('|', alertJobs)],
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&var-job=%s&var-alertgroup=%s&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertVMOverview, std.join('&var-job=', alertJobs), $._config.prometheusRules.alertGroupClusterVM, $._config.prometheusRules.alertGroupClusterVMApp, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.commonThresholds.criticalPanel)),

      local warningPanel =
        alertPanel(
          title='Warning',
          expr='ALERTS{alertname!="Watchdog", severity="warning", alertgroup=~"%s|%s", job=~"%s"} OR on() vector(0)' % [$._config.prometheusRules.alertGroupClusterVM, $._config.prometheusRules.alertGroupClusterVMApp, std.join('|', alertJobs)],
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&var-job=%s&var-alertgroup=%s&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertVMOverview, std.join('&var-job=', alertJobs), $._config.prometheusRules.alertGroupClusterVM, $._config.prometheusRules.alertGroupClusterVMApp, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.commonThresholds.warningPanel)),

      local vmStatsPanels = [
        statPanel.new(
          title=tpl.panel.title,
          description='%s\n\nVM monitoring template: _%s_' % [tpl.panel.description, tpl.templateName],
          datasource=tpl.panel.datasource,
          colorMode=tpl.panel.colorMode,
          graphMode=tpl.panel.graphMode,
          unit=tpl.panel.unit,
          decimals=tpl.panel.decimals,
        )
        .addTarget(prometheus.target(tpl.panel.expr))
        .addMappings(tpl.panel.mappings)
        .addDataLinks(tpl.panel.dataLinks)
        .addThresholds($.grafanaThresholds(tpl.panel.thresholds))
        {
          gridPos: {
            x: tpl.panel.gridPos.x,
            y: tpl.panel.gridPos.y,
            w: tpl.panel.gridPos.w,
            h: tpl.panel.gridPos.h,
          },
        }
        for tpl in vmTemplates
        if (std.objectHas(tpl, 'panel') && tpl.panel != {})
      ],

      local vmAppStatsPanels(index, app) = [
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
        .addDataLinks(
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
            []
        )
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
            vmAppStatsPanels(app.index, app.item)
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
          tags=$._config.grafanaDashboards.tags.k8sVMs,
          uid=vmUid,
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
          $.grafanaTemplates.jobTemplate('label_values(node_uname_info{cluster=~"$cluster", pod=~"virt-launcher.*"}, job)', hide='variable'),
        ])
        .addPanels(
          [
            row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
            criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
            warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
            row.new('VM') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
            text.new('CPU') { gridPos: { x: 0, y: 5, w: 6, h: 1 } },
            text.new('RAM') { gridPos: { x: 6, y: 5, w: 6, h: 1 } },
            text.new('Disk') { gridPos: { x: 12, y: 5, w: 6, h: 1 } },
            text.new('Network') { gridPos: { x: 18, y: 5, w: 6, h: 1 } },
          ] + vmStatsPanels + applicationPanels(vmApps)
        ),
    };
    if $.isClusterMonitoring() then
      local isMulti = std.length($._config.clusterMonitoring.clusters) > 1;
      {
        [local fieldName = 'vm-monitoring-%s' % vm.name; if isMulti then cluster.name + fieldName else fieldName]:
          vmDashboard(
            local id = $._config.grafanaDashboards.ids.vmMonitoring;
            if isMulti then $.getCustomUid([cluster.name, id, vm.name]) else $.getCustomUid([id, vm.name]),
            local name = 'VM Monitoring';
            if isMulti then $.getCustomName([cluster.name, name, vm.name]) else $.getCustomName([name, vm.name]),
            $.getAlertJobs(vm),
            $.getTemplates($._config.templates.L2.vm, vm),
            $.getApps($._config.templates.L1.vmApps, vm)
          ).dashboard
        for cluster in $._config.clusterMonitoring.clusters
        if (std.objectHas(cluster, 'vms') && std.length(cluster.vms) > 0)
        for vm in cluster.vms
      }
    else
      {},
}
