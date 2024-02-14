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

      local criticalPanel =
        alertPanel(
          title='Critical',
          expr='sum(ALERTS{cluster="$cluster", alertname!="Watchdog", alertstate=~"firing", severity="critical", alertgroup=~"%s"}) OR on() vector(0)' % std.join('|', alertGroups)
        )
        .addDataLinks(
          $.updateDataLinksCommonArgs(
            [{ title: 'K8s Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&%s&var-alertgroup=%s' % [$._config.grafanaDashboards.ids.alertKaasOverview, $._config.grafanaDashboards.dataLinkCommonArgs, std.join('&var-alertgroup=', alertGroups)] }]
          )
        )
        .addThresholds($.grafanaThresholds($._config.templates.commonThresholds.criticalPanel)),

      local warningPanel =
        alertPanel(
          title='Warning',
          expr='sum(ALERTS{cluster="$cluster", alertname!="Watchdog", alertstate=~"firing", severity="warning", alertgroup=~"%s"}) OR on() vector(0)' % std.join('|', alertGroups)
        )
        .addDataLinks(
          $.updateDataLinksCommonArgs(
            [{ title: 'K8s Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&%s&var-alertgroup=%s' % [$._config.grafanaDashboards.ids.alertKaasOverview, $._config.grafanaDashboards.dataLinkCommonArgs, std.join('&var-alertgroup=', alertGroups)] }]
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

      local links = (if $._config.grafanaDashboards.isLoki then [explorerLink] else [])
                    + [dNationLink],

      local varTemplates =
        [
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.alertManagerTemplate(),
          $.grafanaTemplates.clusterTemplate('label_values(kaas, cluster)'),
          $.grafanaTemplates.jobTemplate('label_values(node_exporter_build_info{cluster="$cluster", pod!~"virt-launcher.*|"}, job)', hide='variable'),
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
          ] + k8sStatsPanels
        ),
    };
    if $.isKaasMonitoring() then
      {
        ['kaas-l1-' + 'monitoring']:
          clusterDashboard(
            cluster,
            $._config.grafanaDashboards.ids.kaasL1Monitoring,
            'KaaS L1 Monitoring',
            $.getTemplates($._config.templates.L1.k8s, cluster),
          ).dashboard
        for cluster in $._config.kaasMonitoring.clusters
      }
    else
      {},
}
