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

/* Testbed dashboard list */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local statPanel = grafana.panel.stat;
local dashboardListPanel = grafana.panel.dashboardList;
local row = grafana.panel.row;

{
  grafanaDashboards+::
    local testbedDashboard() = {
      local dNationLink =
        dashboard.link.link.new('dNation - Making Cloud Easy', 'https://www.dNation.cloud/')
        + dashboard.link.link.withIcon('cloud')
        + dashboard.link.link.options.withTargetBlank(true),

      local dashboardList =
        dashboardListPanel.new('Dashboard list for Testbed')
        + dashboardListPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + dashboardListPanel.panelOptions.withDescription('List of all available dashboards for testbed')
        + dashboardListPanel.options.withShowRecentlyViewed(false)
        + dashboardListPanel.options.withShowSearch(true)
        + dashboardListPanel.options.withShowHeadings(false)
        + dashboardListPanel.options.withTags(['testbed-dashboard']),

      local statAlert(title, expr) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.options.withGraphMode('none') + statPanel.options.withColorMode('background') + statPanel.options.reduceOptions.withCalcs(['last'])
        + statPanel.queryOptions.withTargets([{ type: 'single', expr: expr, refId: 'A' }]),

      local criticalPanel =
        statAlert('Critical', 'sum(ALERTS{infrastructure="testbed", alertname!="Watchdog", alertstate=~"firing", severity="critical"}) OR on() vector(0)')
        + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs([{ title: 'Testbed Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&%s' % [$._config.grafanaDashboards.ids.alertTestbedOverview, $._config.grafanaDashboards.dataLinkCommonArgsNoCluster] }]))
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds($._config.templates.commonThresholds.criticalPanel)),

      local warningPanel =
        statAlert('Warning', 'sum(ALERTS{infrastructure="testbed", alertname!="Watchdog", alertstate=~"firing", severity="warning"}) OR on() vector(0)')
        + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs([{ title: 'Testbed Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&%s' % [$._config.grafanaDashboards.ids.alertTestbedOverview, $._config.grafanaDashboards.dataLinkCommonArgsNoCluster] }]))
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds($._config.templates.commonThresholds.warningPanel)),

      dashboard:
        dashboard.new('IaaS monitoring')
        + dashboard.withUid($._config.grafanaDashboards.ids.testbed)
        + dashboard.withTags($._config.grafanaDashboards.tags.testbed)
        + dashboard.withEditable($._config.grafanaDashboards.editable) + dashboard.withRefresh($._config.grafanaDashboards.refresh)
        + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
        + $._config.grafanaDashboards.tooltip
        + dashboard.withTimezone('browser')
        + dashboard.withLinks([dNationLink])
        + dashboard.withVariables([$.grafanaTemplates.datasourceTemplate()])
        + dashboard.withPanels([
          row.new('Alerts') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
          warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
          row.new('Dashboards') + { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
          dashboardList { gridPos: { x: 0, y: 5, w: 24, h: 20 } },
        ]),
    };
    if $.isTestbedMonitoring() then
      { 'iaas-monitoring': testbedDashboard().dashboard }
    else {},
}
