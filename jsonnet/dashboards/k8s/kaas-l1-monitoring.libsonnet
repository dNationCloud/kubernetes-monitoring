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
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local statPanel = grafana.panel.stat;
local row = grafana.panel.row;
local text = grafana.panel.text;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+::
    local clusterDashboard(cluster, dashboardUid, dashboardName, clusterTemplates) = {
      local explorerLink =
        dashboard.link.link.new('Logs', '/explore?orgId=1&left=%5B%22now-7d%22,%22now%22,%22$datasource_logs%22,%7B%22expr%22:%22%7Bnamespace%3D%5C%22kube-system%5C%22,%20stream%3D%5C%22stderr%5C%22%7D%20%7C~%20%5C%22(%3Fi)error%5C%22%20!~%20%5C%22Final%20error%20received,%20removing%20PVC%20.%2B%20from%20claims%20in%20progress%5C%22%22%7D,%7B%22mode%22:%22Logs%22%7D,%7B%22ui%22:%5Btrue,true,true,%22numbers%22%5D%7D%5D')
        + dashboard.link.link.withIcon('doc'),

      local dNationLink =
        dashboard.link.link.new('dNation - Making Cloud Easy', 'https://www.dNation.cloud/')
        + dashboard.link.link.withIcon('cloud')
        + dashboard.link.link.options.withTargetBlank(true),

      local statAlert(title, expr) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.options.withGraphMode('none') + statPanel.options.withColorMode('background') + statPanel.options.reduceOptions.withCalcs(['last'])
        + statPanel.queryOptions.withTargets([{ type: 'single', expr: expr, refId: 'A' }]),

      local alertGroups = [$._config.prometheusRules.alertGroupCluster, $._config.prometheusRules.alertGroupClusterApp],

      local criticalPanel =
        statAlert('Critical', 'sum(ALERTS{cluster="$cluster", alertname!="Watchdog", alertstate=~"firing", severity="critical", alertgroup=~"%s"}) OR on() vector(0)' % std.join('|', alertGroups))
        + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs([{ title: 'K8s Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&%s&var-alertgroup=%s' % [$._config.grafanaDashboards.ids.alertKaasOverview, $._config.grafanaDashboards.dataLinkCommonArgs, std.join('&var-alertgroup=', alertGroups)] }]))
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds($._config.templates.commonThresholds.criticalPanel)),

      local warningPanel =
        statAlert('Warning', 'sum(ALERTS{cluster="$cluster", alertname!="Watchdog", alertstate=~"firing", severity="warning", alertgroup=~"%s"}) OR on() vector(0)' % std.join('|', alertGroups))
        + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs([{ title: 'K8s Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&%s&var-alertgroup=%s' % [$._config.grafanaDashboards.ids.alertKaasOverview, $._config.grafanaDashboards.dataLinkCommonArgs, std.join('&var-alertgroup=', alertGroups)] }]))
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds($._config.templates.commonThresholds.warningPanel)),

      local statBase(title, p, desc) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource') + statPanel.panelOptions.withDescription(desc)
        + (if std.objectHas(p, 'colorMode') then statPanel.options.withColorMode(p.colorMode) else {})
        + (if std.objectHas(p, 'graphMode') then statPanel.options.withGraphMode(p.graphMode) else {})
        + (if std.objectHas(p, 'unit') then statPanel.standardOptions.withUnit(p.unit) else {})
        + (if std.objectHas(p, 'decimals') && p.decimals != null then statPanel.standardOptions.withDecimals(p.decimals) else {}),

      local k8sStatsPanels = [
        statBase(tpl.panel.title, tpl.panel, '%s\n\nKaaS monitoring template: _%s_' % [tpl.panel.description, tpl.templateName])
        + statPanel.queryOptions.withTargets([prometheus.withExpr(tpl.panel.expr)])
        + statPanel.standardOptions.withMappings(tpl.panel.mappings)
        + statPanel.standardOptions.withLinks($.finalizeDataLinksUrl(cluster, tpl))
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds(tpl.panel.thresholds))
        + { gridPos: { x: tpl.panel.gridPos.x, y: tpl.panel.gridPos.y, w: tpl.panel.gridPos.w, h: tpl.panel.gridPos.h } }
        for tpl in clusterTemplates
        if (std.objectHas(tpl, 'panel') && tpl.panel != {})
      ],

      local varTemplates = [
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.alertManagerTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(kaas, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(node_exporter_build_info{cluster="$cluster", pod!~"virt-launcher.*|"}, job)', hide='variable'),
        $.grafanaTemplates.masterInstanceTemplate(),
        $.grafanaTemplates.workerInstanceTemplate(),
      ] + if $._config.grafanaDashboards.isLoki then [$.grafanaTemplates.datasourceLogsTemplate(hide='variable')] else [],

      local txt(t, x, y, w) = text.new(t) + { gridPos: { x: x, y: y, w: w, h: 1 } },

      dashboard:
        dashboard.new(dashboardName)
        + dashboard.withUid(dashboardUid) + dashboard.withTags($._config.grafanaDashboards.tags.kaasMonitoring)
        + dashboard.withEditable($._config.grafanaDashboards.editable) + dashboard.withRefresh($._config.grafanaDashboards.refresh)
        + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
        + $._config.grafanaDashboards.tooltip
        + dashboard.withTimezone('browser')
        + dashboard.withLinks((if $._config.grafanaDashboards.isLoki then [explorerLink] else []) + [dNationLink]) + dashboard.withVariables(varTemplates)
        + dashboard.withPanels([
          row.new('Alerts') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
          warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
          row.new('Control Plane') + { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
          row.new('Overview') + { gridPos: { x: 0, y: 8, w: 24, h: 1 } },
          row.new('Master Nodes Metrics') + { gridPos: { x: 0, y: 15, w: 24, h: 1 } },
          txt('CPU', 0, 16, 6),
          txt('RAM', 6, 16, 6),
          txt('Disk', 12, 16, 6),
          txt('Network', 18, 16, 6),
          row.new('Worker Nodes Metrics') + { gridPos: { x: 0, y: 23, w: 24, h: 1 } },
          txt('CPU', 0, 24, 6),
          txt('RAM', 6, 24, 6),
          txt('Disk', 12, 24, 6),
          txt('Network', 18, 24, 6),
        ] + k8sStatsPanels),
    };
    if $.isKaasMonitoring() then
      {
        ['kaas-l1-' + 'monitoring']:
          clusterDashboard(cluster, $._config.grafanaDashboards.ids.kaasL1Monitoring, 'KaaS L1 Monitoring', $.getTemplates($._config.templates.L1.k8s, cluster)).dashboard
        for cluster in $._config.kaasMonitoring.clusters
      }
    else {},
}
