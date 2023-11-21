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

/* K8s main dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local statPanel = grafana.statPanel;
local row = grafana.row;
local link = grafana.link;
local text = grafana.text;

local rowWidth = 24;


local getGridX(index, panelWidth) =
  /**
   * Compute element grid X coordinate based on index number
   *
   * @param index The index of element.
   * @param panelWidth Width of panels.
   * @return grid X coordinate as number.
  */
  local panelsInRow = std.floor(rowWidth / panelWidth);
  local columnIndex = index % panelsInRow;
  columnIndex * panelWidth;

local getGridY(offset, index, panelWidth, panelHeight) =
  /**
   * Compute element grid Y coordinate based on index number
   *
   * @param offset Offset of Y position.
   * @param index The index of element.
   * @param panelWidth Width of panels.
   * @param panelHeight Height of panels.
   * @return grid Y coordinate as number.
  */
  local panelsInRow = std.floor(rowWidth / panelWidth);
  local rowIndex = std.floor(index / panelsInRow);
  (rowIndex * panelHeight) + offset;

local sumAppWidth(apps) =
  /**
   * Summation of widths of the individual applications
   *
   * @param apps Array of applications you want to add.
   * @return the sum of individual applications.
  */
  std.foldl(
    function(x, y)
    (
    if (x + y) > std.floor((x + y)/rowWidth)*rowWidth && x < std.floor((x + y)/rowWidth)*rowWidth then
      (x + y + (x + y - std.floor((x + y)/rowWidth)*rowWidth))
    else
      (x + y)
    ),
  [
    temp.panel.gridPos.w
    for app in apps
    for temp in app.templates
  ], 0);

local sumTempWidth(templates) = 
  std.foldl(function(x, y) (x + y), [
    temp.panel.gridPos.w
    for temp in templates
  ], 0);  
{
  grafanaDashboards+::
    local clusterDashboard(cluster, dashboardUid, dashboardName, clusterTemplates, clusterApps=[], clusterVMs=[]) = {

      local explorerLinkUrl =
          '/explore?orgId=1&left=%5B%22now-7d%22,%22now%22,%22$datasource_logs%22,%7B%22expr%22:%22%7Bnamespace%3D%5C%22kube-system%5C%22,%20stream%3D%5C%22stderr%5C%22%7D%20%7C~%20%5C%22(%3Fi)error%5C%22%20!~%20%5C%22Final%20error%20received,%20removing%20PVC%20.%2B%20from%20claims%20in%20progress%5C%22%22%7D,%7B%22mode%22:%22Logs%22%7D,%7B%22ui%22:%5Btrue,true,true,%22numbers%22%5D%7D%5D',

      local explorerLink =
        link.dashboards(
          title='Logs',
          tags=[],
          icon='doc',
          url=explorerLinkUrl,
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

      local alertGroups = [$._config.prometheusRules.alertGroupCluster, $._config.prometheusRules.alertGroupClusterApp],
      local alertVMGroups =
        if std.length(clusterVMs) > 0 then
          [$._config.prometheusRules.alertGroupClusterVM, $._config.prometheusRules.alertGroupClusterVMApp]
        else [],

      local criticalPanel =
        alertPanel(
          title='Critical',
          expr='sum(ALERTS{cluster=~"$cluster", alertname!="Watchdog", alertstate=~"firing", severity="critical", alertgroup=~"%s"}) OR on() vector(0)' % std.join('|', alertGroups + alertVMGroups)
        )
        .addDataLinks(
          $.updateDataLinksCommonArgs(
            [{ title: 'K8s Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&%s&var-alertgroup=%s' % [$._config.grafanaDashboards.ids.alertKaasOverview, $._config.grafanaDashboards.dataLinkCommonArgs, std.join('&var-alertgroup=', alertGroups + alertVMGroups)] }]
          )
        )
        .addThresholds($.grafanaThresholds($._config.templates.commonThresholds.criticalPanel)),

      local warningPanel =
        alertPanel(
          title='Warning',
          expr='sum(ALERTS{cluster=~"$cluster", alertname!="Watchdog", alertstate=~"firing", severity="warning", alertgroup=~"%s"}) OR on() vector(0)' % std.join('|', alertGroups + alertVMGroups)
        )
        .addDataLinks(
          $.updateDataLinksCommonArgs(
            [{ title: 'K8s Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&%s&var-alertgroup=%s' % [$._config.grafanaDashboards.ids.alertKaasOverview, $._config.grafanaDashboards.dataLinkCommonArgs, std.join('&var-alertgroup=', alertGroups + alertVMGroups)] }]
           )
        )
        .addThresholds($.grafanaThresholds($._config.templates.commonThresholds.warningPanel)),

      local k8sStatsPanels = [
        statPanel.new(
          title=tpl.panel.title,
          description='%s\n\nKaaS monitoring template: _%s_' % [tpl.panel.description, tpl.templateName],
          datasource=tpl.panel.datasource,
          colorMode=tpl.panel.colorMode,
          graphMode=tpl.panel.graphMode,
          unit=tpl.panel.unit,
          decimals=tpl.panel.decimals,
        )
        .addTarget(prometheus.target(tpl.panel.expr))
        .addMappings(tpl.panel.mappings)
        .addDataLinks($.finalizeDataLinksUrl(cluster, tpl))
        .addThresholds($.grafanaThresholds(tpl.panel.thresholds))
        {
          gridPos: {
            x: tpl.panel.gridPos.x,
            y: tpl.panel.gridPos.y,
            w: tpl.panel.gridPos.w,
            h: tpl.panel.gridPos.h,
          },
        }
        for tpl in clusterTemplates
        if (std.objectHas(tpl, 'panel') && tpl.panel != {})
      ],
      local k8sAppStatsPanels(app, prevAppLenght) = [
        local tpl = template.item;
        local tplIndex = template.index;
        local prevTempWidth =
          if tplIndex > 0 then
            sumTempWidth(std.slice(app.templates,0,tplIndex,1))
          else
            0;
        local widthRowLeft = 
          // in jsonnet when dividend or divisor is negative then it returns negative reminder
          if (prevTempWidth + prevAppLenght) > 24 then
            ((rowWidth - (prevTempWidth + prevAppLenght)) % rowWidth) + rowWidth
          else
            (rowWidth - (prevTempWidth + prevAppLenght)) % rowWidth;
        local appGridX =
          if std.type(tpl.panel.gridPos.x) == 'number' then
            tpl.panel.gridPos.x
          else if widthRowLeft >= tpl.panel.gridPos.w || widthRowLeft == 0 then
            (prevTempWidth + prevAppLenght) % rowWidth
          else
            (prevTempWidth + prevAppLenght) % widthRowLeft;
        local appGridY =
          if std.type(tpl.panel.gridPos.y) == 'number' then
            tpl.panel.gridPos.y
          else
            29 + tpl.panel.gridPos.h * std.floor(prevAppLenght/rowWidth);  // `29` -> init Y position in application row;
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
          $.updateDataLinksCommonArgs(
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
            row.new('Applications') { gridPos: { x: 0, y: 28, w: 24, h: 1 } },
          ] +
          std.flattenArrays([
            if app.index > 0 then
              k8sAppStatsPanels(app.item, sumAppWidth(std.slice(apps,0,app.index,1)))
            else
              k8sAppStatsPanels(app.item, 0)
            for app in $.zipWithIndex(apps)
          ])
        else
          [],

      local appPanels = applicationPanels(clusterApps),

      local vmPanel(index, vm, offset) = [
        local panelHeight = tpl.panel.gridPos.h;
        local panelWidth = tpl.panel.gridPos.w;

        local gridX =
          if std.type(tpl.panel.gridPos.x) == 'number' then
            tpl.panel.gridPos.x
          else
            getGridX(index, panelWidth);

        local gridY =
          if std.type(tpl.panel.gridPos.y) == 'number' then
            tpl.panel.gridPos.y
          else
            getGridY(offset, index, panelWidth, panelHeight);

        statPanel.new(
          title='VM %s' % vm.name,
          datasource=tpl.panel.datasource,
          graphMode=tpl.panel.graphMode,
          colorMode=tpl.panel.colorMode,
          unit=tpl.panel.unit,
          decimals=tpl.panel.decimals,
        )
        .addTarget({ type: 'single', instant: true, expr: tpl.panel.expr % { job: std.join('|', $.getAlertJobs(vm)), groupVM: $._config.prometheusRules.alertGroupClusterVM, groupVMApp: $._config.prometheusRules.alertGroupClusterVMApp, maxWarnings: $._config.grafanaDashboards.constants.maxWarnings } })
        .addThresholds($.grafanaThresholds(tpl.panel.thresholds))
        .addMappings(tpl.panel.mappings)
        .addDataLinks(
          $.updateDataLinksCommonArgs(
            if std.length(tpl.panel.dataLinks) > 0 then
              tpl.panel.dataLinks % { job: vm.jobName }
            else
              local id = $._config.grafanaDashboards.ids.vmMonitoring;
              local vmUid = $.getCustomUid([id, vm.name]);
              [{ title: 'VM Monitoring', url: '/d/%s?%s&var-job=%s' % [vmUid, $._config.grafanaDashboards.dataLinkCommonArgs, vm.jobName] }]
          )
        )
        {
          gridPos: {
            x: gridX,
            y: gridY,
            w: panelWidth,
            h: panelHeight,
          },
        }
        for tpl in $.getTemplates($._config.templates.L1.vm, vm)
        if (std.objectHas(tpl, 'panel') && tpl.panel != {})
      ],

      local vmPanels(vms) =
        if std.length(vms) > 0 then
          local appLength = std.length(appPanels);
          local offset =
            if appLength > 0 then
              local sortAppPanels = std.sort(appPanels, function(app) app.gridPos.y + app.gridPos.h);
              sortAppPanels[appLength - 1].gridPos.y + sortAppPanels[appLength - 1].gridPos.h + 1
            else
              22;
          [
            row.new('Virtual Machines') { gridPos: { x: 0, y: offset, w: 24, h: 1 } },
          ] +
          std.flattenArrays([
            vmPanel(vm.index, vm.item, offset + 1)
            for vm in $.zipWithIndex(vms)
          ])
        else
          [],

      local links = (if $._config.grafanaDashboards.isLoki then [explorerLink] else [])
                    + [dNationLink],

      local varTemplates =
        [
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.alertManagerTemplate(),
          $.grafanaTemplates.clusterTemplate('label_values(kaas, cluster)'),
          $.grafanaTemplates.jobTemplate('label_values(node_exporter_build_info{cluster=~"$cluster", pod!~"virt-launcher.*|"}, job)', hide='variable'),
          $.grafanaTemplates.masterInstanceTemplate(),
          $.grafanaTemplates.workerInstanceTemplate(),
        ]
        + if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.datasourceLogsTemplate(hide='variable')] else [],

      dashboard:
        dashboard.new(
          dashboardName,
          editable=$._config.grafanaDashboards.editable,
          graphTooltip=$._config.grafanaDashboards.tooltip,
          refresh=$._config.grafanaDashboards.refresh,
          time_from=$._config.grafanaDashboards.time_from,
          tags=$._config.grafanaDashboards.tags.kaasMonitoring,
          uid=dashboardUid,
        )
        .addLinks(links)
        .addTemplates(varTemplates)
        .addPanels(
          [
            row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
            criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
            warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
            row.new('Control Plane') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
            row.new('Overview') { gridPos: { x: 0, y: 8, w: 24, h: 1 } },
            row.new('Master Nodes Metrics') { gridPos: { x: 0, y: 15, w: 24, h: 1 } },
            text.new('CPU') { gridPos: { x: 0, y: 16, w: 6, h: 1 } },
            text.new('RAM') { gridPos: { x: 6, y: 16, w: 6, h: 1 } },
            text.new('Disk') { gridPos: { x: 12, y: 16, w: 6, h: 1 } },
            text.new('Network') { gridPos: { x: 18, y: 16, w: 6, h: 1 } },
            row.new('Worker Nodes Metrics') { gridPos: { x: 0, y: 22, w: 24, h: 1 } },
            text.new('CPU') { gridPos: { x: 0, y: 23, w: 6, h: 1 } },
            text.new('RAM') { gridPos: { x: 6, y: 23, w: 6, h: 1 } },
            text.new('Disk') { gridPos: { x: 12, y: 23, w: 6, h: 1 } },
            text.new('Network') { gridPos: { x: 18, y: 23, w: 6, h: 1 } },
          ] + k8sStatsPanels + appPanels + vmPanels(clusterVMs)
        ),
    };
    if $.isKaasMonitoring() then
      {
        ['kaas-monitoring-%s' % cluster.name]:
          clusterDashboard(
            cluster,
            $.getCustomUid([$._config.grafanaDashboards.ids.kaasL1Monitoring, cluster.name]),
            $.getCustomName(['KaaS Monitoring', cluster.name]),
            $.getTemplates($._config.templates.L1.k8s, cluster),
            $.getApps($._config.templates.L1.k8sApps, cluster),
            if std.objectHas(cluster, 'vms') then cluster.vms else [],
          ).dashboard
        for cluster in $._config.kaasMonitoring.clusters
        if (std.objectHas(cluster, 'apps') || !$.hasDefaultTemplates(cluster, $._config.templates.L1.k8s) || std.objectHas(cluster, 'vms'))
      } +
      if $.isAnyDefault($._config.kaasMonitoring.clusters, $._config.templates.L1.k8s) then
        {
          'kaas-l1-monitoring': clusterDashboard({}, $._config.grafanaDashboards.ids.kaasL1Monitoring, 'KaaS Monitoring', $.getTemplates($._config.templates.L1.k8s)).dashboard,
        }
      else
        {}
    else
      {},
}
