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

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local dashlist = grafana.dashlist;
local link = grafana.link;
local statPanel = grafana.statPanel;
local row = grafana.row;

{
  grafanaDashboards+::
    local testbedDashboard() = {

      local dNationLink =
        link.dashboards(
          title='dNation - Making Cloud Easy',
          tags=[],
          icon='cloud',
          url='https://www.dNation.cloud/',
          type='link',
          targetBlank=true,
        ),

      local dashboardList =
        dashlist.new(
          title='Dashboard list for Testbed',
          description='List of all available dashboards for testbed',
          recent=false,
          search=true,
          headings=false,
          tags=[
            'testbed-dashboard',
          ],
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
          expr='sum(ALERTS{infrastructure="testbed", alertname!="Watchdog", alertstate=~"firing", severity="critical"}) OR on() vector(0)'
        )
        .addDataLinks(
          $.updateDataLinksCommonArgs(
            [{ title: 'Testbed Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&%s' % [$._config.grafanaDashboards.ids.alertTestbedOverview, $._config.grafanaDashboards.dataLinkCommonArgsNoCluster] }]
          )
        )
        .addThresholds($.grafanaThresholds($._config.templates.commonThresholds.criticalPanel)),

      local warningPanel =
        alertPanel(
          title='Warning',
          expr='sum(ALERTS{infrastructure="testbed", alertname!="Watchdog", alertstate=~"firing", severity="warning"}) OR on() vector(0)'
        )
        .addDataLinks(
          $.updateDataLinksCommonArgs(
            [{ title: 'Testbed Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&%s' % [$._config.grafanaDashboards.ids.alertTestbedOverview, $._config.grafanaDashboards.dataLinkCommonArgsNoCluster] }]
          )
        )
        .addThresholds($.grafanaThresholds($._config.templates.commonThresholds.warningPanel)),


      dashboard:
        dashboard.new(
          title='IaaS monitoring',
          editable=$._config.grafanaDashboards.editable,
          graphTooltip=$._config.grafanaDashboards.tooltip,
          refresh=$._config.grafanaDashboards.refresh,
          time_from=$._config.grafanaDashboards.time_from,
          tags=$._config.grafanaDashboards.tags.testbed,
          uid=$._config.grafanaDashboards.ids.testbed,
        )
        .addLink(dNationLink)
        .addTemplates([$.grafanaTemplates.datasourceTemplate()])
        .addPanels([
          row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
          warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
          row.new('Dashboards') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
          dashboardList { gridPos: { x: 0, y: 5, w: 24, h: 20 } },
        ]),
    };
    if $.isIaasMonitoring() then
      {
        'iaas-monitoring':
          testbedDashboard().dashboard,
      }
    else
      {},
}
