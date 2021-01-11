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
local template = grafana.template;
local row = grafana.row;
local link = grafana.link;
local text = grafana.text;

{
  grafanaDashboards+::
    local clusterDashboard(clusterUid, dashboardName, clusterTemplates, clusterApps=[]) = {
      local containerLink =
        link.dashboards(
          title=if $._config.grafanaDashboards.isLoki then 'Logs Container' else 'Container Detail',
          tags=[],
          icon='dashboard',
          url='/d/%s' % $._config.grafanaDashboards.ids.containerDetail,
          type='link',
        ),
      local explorerLink =
        link.dashboards(
          title='Logs Explorer',
          tags=[],
          icon='doc',
          url='/explore?orgId=1&left=%5B%22now-7d%22,%22now%22,%22$datasource_logs%22,%7B%22expr%22:%22%7Bnamespace%3D%5C%22kube-system%5C%22,%20stream%3D%5C%22stderr%5C%22%7D%20%7C~%20%5C%22(%3Fi)error%5C%22%20!~%20%5C%22Final%20error%20received,%20removing%20PVC%20.%2B%20from%20claims%20in%20progress%5C%22%22%7D,%7B%22mode%22:%22Logs%22%7D,%7B%22ui%22:%5Btrue,true,true,%22numbers%22%5D%7D%5D',
          type='link',
        ),
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
          datasource='$alertmanager',
          graphMode='none',
          colorMode='background',
        )
        .addTarget({ type: 'single', expr: expr }),

      local criticalPanel =
        alertPanel(
          title='Critical',
          expr='ALERTS{alertname!="Watchdog", severity="critical", alertgroup=~"%s|%s"}' % [$._config.prometheusRules.alertGroupCluster, $._config.prometheusRules.alertGroupClusterApp]
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&var-alertgroup=%s&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertClusterOverview, $._config.prometheusRules.alertGroupCluster, $._config.prometheusRules.alertGroupClusterApp, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.commonThresholds.criticalPanel)),
      local warningPanel =
        alertPanel(
          title='Warning',
          expr='ALERTS{alertname!="Watchdog", severity="warning", alertgroup=~"%s|%s"}' % [$._config.prometheusRules.alertGroupCluster, $._config.prometheusRules.alertGroupClusterApp]
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&var-alertgroup=%s&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertClusterOverview, $._config.prometheusRules.alertGroupCluster, $._config.prometheusRules.alertGroupClusterApp, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.commonThresholds.warningPanel)),

      local k8sStatsPanels = [
        statPanel.new(
          title=tpl.panel.title,
          description='%s\n\nK8s monitoring template: _%s_' % [tpl.panel.description, tpl.templateName],
          datasource=tpl.panel.datasource,
          colorMode=tpl.panel.colorMode,
          graphMode=tpl.panel.graphMode,
          unit=tpl.panel.unit,
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
        for tpl in clusterTemplates if (std.objectHas(tpl, 'panel') && tpl.panel != {})
      ],
      local k8sAppStatsPanels(index, app) = [
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
            23;  // `23` -> init Y position in application row;
        statPanel.new(
          title='%s %s' % [tpl.templateName, app.name],
          description='%s\n\nApplication monitoring template: _%s_' % [app.description, tpl.templateName],
          datasource=tpl.panel.datasource,
          colorMode=tpl.panel.colorMode,
          graphMode=tpl.panel.graphMode,
          unit=tpl.panel.unit,
        )
        .addTarget(prometheus.target(tpl.panel.expr % { job: 'job=~"%s"' % app.jobName }))
        .addMappings(tpl.panel.mappings)
        .addDataLinks(
          if std.length(tpl.panel.dataLinks) > 0 then
            tpl.panel.dataLinks
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
            row.new('Applications') { gridPos: { x: 0, y: 22, w: 24, h: 1 } },
          ] +
          std.flattenArrays([
            k8sAppStatsPanels(app.index, app.item)
            for app in $.zipWithIndex(apps)
          ])
        else
          [],
      local datasourceTemplate =
        template.datasource(
          query='prometheus',
          name='datasource',
          current=null,
          label='Datasource',
        ),
      local alertManagerTemplate =
        template.datasource(
          query='camptocamp-prometheus-alertmanager-datasource',
          name='alertmanager',
          current=null,
          label='AlertManager',
          hide='variable',
        ),
      local clusterTemplate =
        template.new(
          name='cluster',
          label='Cluster',
          datasource='$datasource',
          query='label_values(kube_node_info, cluster)',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        ),
      local jobTemplate =
        template.new(
          name='job',
          query='label_values(node_exporter_build_info{cluster=~"$cluster", pod!~""}, job)',
          label='Job',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        ),
      local datasourceLogsTemplate =
        template.datasource(
          name='datasource_logs',
          label='Logs datasource',
          query='loki',
          current=null,
          hide='variable',
        ),
      local links = [
                      containerLink,
                    ]
                    + (if $._config.grafanaDashboards.isLoki then [explorerLink] else [])
                    + [
                      monitoringLink,
                      dNationLink,
                    ],
      local varTemplates = [
                             datasourceTemplate,
                             alertManagerTemplate,
                             clusterTemplate,
                             jobTemplate,
                           ]
                           + if $._config.grafanaDashboards.isLoki then [datasourceLogsTemplate] else [],

      dashboard: dashboard.new(
        dashboardName,
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sMonitoring,
        uid=clusterUid,
      )
                 .addLinks(links)
                 .addTemplates(varTemplates)
                 .addPanels(
        [
          row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
          warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
          row.new('Overview') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
          row.new('Control Plane Components Health') { gridPos: { x: 0, y: 11, w: 24, h: 1 } },
          row.new('Node Metrics (including Master)') { gridPos: { x: 0, y: 15, w: 24, h: 1 } },
          text.new('CPU') { gridPos: { x: 0, y: 16, w: 6, h: 1 } },
          text.new('RAM') { gridPos: { x: 6, y: 16, w: 6, h: 1 } },
          text.new('Disk') { gridPos: { x: 12, y: 16, w: 6, h: 1 } },
          text.new('Network') { gridPos: { x: 18, y: 16, w: 6, h: 1 } },
        ] + k8sStatsPanels + applicationPanels(clusterApps)
      ),
    };
    if $._config.clusterMonitoring.enabled && std.length($._config.clusterMonitoring.clusters) > 0 then
      {
        local getUid(obj) = '%s%s' % [$._config.grafanaDashboards.ids.k8sMonitoring, std.asciiLower(obj.name)],
        local getName(obj) = 'Kubernetes Monitoring %s' % obj.name,

        ['k8s-monitoring-%s' % cluster.name]: clusterDashboard(getUid(cluster), getName(cluster), $.getTemplates($._config.templates.k8s, cluster), $.getApps($._config.templates.k8sApps, cluster)).dashboard
        for cluster in $._config.clusterMonitoring.clusters
        if (std.objectHas(cluster, 'apps') || std.objectHas(cluster, 'templates'))
      } +
      if $.isAnyDefault($._config.clusterMonitoring.clusters) then
        {
          'k8s-monitoring': clusterDashboard($._config.grafanaDashboards.ids.k8sMonitoring, 'Kubernetes Monitoring', $.getTemplates($._config.templates.k8s)).dashboard,
        }
      else
        {}
    else
      {},
}
