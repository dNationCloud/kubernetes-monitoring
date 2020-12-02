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
local template = grafana.template;
local row = grafana.row;
local link = grafana.link;
local text = grafana.text;


local sumArr(arr) =
  /**
   * Compute sum of array elements.
   *
   * @param arrays The input array.
   * @return sum as number.
   */
  std.foldl(function(x, y) x + y, arr, 0);

local maxArr(arr) =
  /**
   * Compute max of array elements.
   *
   * @param arrays The input array.
   * @return max as number.
   */
  std.foldl(function(x, y) std.max(x, y), arr, 0);

local zipWithIndex(arr) =
  /**
   * Enumarate array elements.
   *
   * @param arrays The input array.
   * @return indexed array.
  */
  std.makeArray(std.length(arr), function(i) [i, arr[i]]);

local applicationRowHeight(index, templates) =
  /**
   * Compute application row height.
   *
   * @param index The index of host with application.
   * @param templates The input application templates array.
   * @return application row height as number.
  */
  maxArr([
    local appItemGridY =
      if std.objectHas(template, 'grid') && std.objectHas(template.grid, 'posY') then
        (template.grid.posY * 3) + 4  // `3` -> stat panel height
      else
        (index * 3) + 4;

    appItemGridY
    for template in templates
  ]);

local getGridY(index, hosts) =
  /**
   * Compute element grid Y coordinate based on host index number
   *
   * @param index The index of host.
   * @param hosts The input hosts array.
   * @return grid Y coordinate as number.
  */
  local initGridY = 4;
  local hostHeight = 7;
  local hostsPasts = if index > 0 then hosts[:index] else [];
  local hostsPastsApps = if std.length(hostsPasts) > 0 then std.flattenArrays([host.apps for host in hostsPasts if std.objectHas(host, 'apps')]) else [];
  local hostsPastsAppsHeight = if std.length(hostsPastsApps) > 0 then sumArr([
    applicationRowHeight(index_app[0], index_app[1].templates)
    for index_app in zipWithIndex(hostsPastsApps)
  ]) else 0;
  initGridY + (index * hostHeight) + hostsPastsAppsHeight;

{
  grafanaDashboards+::
    if std.length([$._config.hostMonitoring.hosts]) > 0 && $._config.hostMonitoring.enabled then
      {
        'host-monitoring':
          local appMonitoringLink =
            link.dashboards(
              title='Application Monitoring',
              tags=[],
              url='/d/%s' % $._config.grafanaDashboards.ids.appMonitoring,
              type='link',
            );

          local k8sMonitoringLink =
            link.dashboards(
              title='Kubernetes Monitoring',
              tags=[],
              url='/d/%s' % $._config.grafanaDashboards.ids.k8sMonitoring,
              type='link',
            );

          local dNationLink =
            link.dashboards(
              title='dNation - Making Cloud Easy',
              tags=[],
              icon='cloud',
              url='https://www.dNation.cloud/',
              type='link',
              targetBlank=true,
            );

          local alertPanel(title, expr) =
            statPanel.new(
              title=title,
              datasource='$alertmanager',
              graphMode='none',
              colorMode='background',
            )
            .addTarget({ type: 'single', expr: expr });

          local criticalPanel =
            alertPanel(
              title='Critical',
              expr='ALERTS{alertname!="Watchdog", severity="critical", alertgroup=~"%s|%s"}' % [$._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp],
            )
            .addDataLink({ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&var-alertgroup=%s&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertOverview, $._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp, $._config.grafanaDashboards.dataLinkCommonArgs] })
            .addThresholds($.grafanaThresholds($._config.commonThresholds.criticalPanel));

          local warningPanel =
            alertPanel(
              title='Warning',
              expr='ALERTS{alertname!="Watchdog", severity="warning", alertgroup=~"%s|%s"}' % [$._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp],
            )
            .addDataLink({ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&var-alertgroup=%s&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertOverview, $._config.prometheusRules.alertGroupHost, $._config.prometheusRules.alertGroupHostApp, $._config.grafanaDashboards.dataLinkCommonArgs] })
            .addThresholds($.grafanaThresholds($._config.commonThresholds.warningPanel));

          local datasourceTemplate =
            template.datasource(
              query='prometheus',
              name='datasource',
              current=null,
              label='Datasource',
            );

          local alertManagerTemplate =
            template.datasource(
              query='camptocamp-prometheus-alertmanager-datasource',
              name='alertmanager',
              current=null,
              label='AlertManager',
              hide='variable',
            );

          local clusterTemplate =
            template.new(
              name='cluster',
              label='Cluster',
              datasource='$datasource',
              query='label_values(kube_node_info, cluster)',
              sort=$._config.grafanaDashboards.templateSort,
              refresh=$._config.grafanaDashboards.templateRefresh,
              hide='variable',
            );

          local percentStatPanel(title, expr) =
            statPanel.new(
              title=title,
              datasource='$datasource',
              colorMode='background',
              unit='percent',
            )
            .addTarget(prometheus.target(expr));

          local overallUtilizationCPUPanel(host) =
            percentStatPanel(
              title='Overall Utilization',
              expr='avg(%s)' % $._config.templates.nodeCpuUtilization.expr % { job: 'job=~"%s"' % host.jobName },
            )
            .addThresholds($.grafanaThresholds($._config.templates.nodeCpuUtilization.thresholds))
            .addDataLink({ title: 'System Overview', url: '/d/%s?var-job=%s&%s' % [$._config.grafanaDashboards.ids.nodeExporter, host.jobName, $._config.grafanaDashboards.dataLinkCommonArgs] });

          local overallUtilizationRAMPanel(host) =
            percentStatPanel(
              title='Overall Utilization',
              expr='avg(%s)' % $._config.templates.nodeRamUtilization.expr % { job: 'job=~"%s"' % host.jobName },
            )
            { description: 'The percentage of the memory utilization is calculated by:\n```\n1 - (<memory available>/<memory total>)\n```' }
            .addThresholds($.grafanaThresholds($._config.templates.nodeRamUtilization.thresholds))
            .addDataLink({ title: 'System Overview', url: '/d/%s?var-job=%s&%s' % [$._config.grafanaDashboards.ids.nodeExporter, host.jobName, $._config.grafanaDashboards.dataLinkCommonArgs] });

          local overallUtilizationDiskPanel(host) =
            percentStatPanel(
              title='Overall Utilization',
              expr='avg(%s)' % $._config.templates.nodeDiskUtilization.expr % { job: 'job=~"%s"' % host.jobName },
            )
            { description: 'The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition.' }
            .addThresholds($.grafanaThresholds($._config.templates.nodeDiskUtilization.thresholds))
            .addDataLink({ title: 'System Overview', url: '/d/%s?var-job=%s&%s' % [$._config.grafanaDashboards.ids.nodeExporter, host.jobName, $._config.grafanaDashboards.dataLinkCommonArgs] });

          local networkErrorsPanel(host) =
            percentStatPanel(
              title='Errors',
              expr='sum(%s)' % $._config.templates.nodeNetworkErrors.expr % { job: 'job=~"%s"' % host.jobName },
            )
            { fieldConfig: { defaults: { unit: 'pps' } } }
            .addThresholds($.grafanaThresholds($._config.templates.nodeNetworkErrors.thresholds))
            .addDataLink({ title: 'System Overview', url: '/d/%s?var-job=%s&%s' % [$._config.grafanaDashboards.ids.nodeExporter, host.jobName, $._config.grafanaDashboards.dataLinkCommonArgs] });

          local valueStatPanel(title, expr, unit='none') =
            statPanel.new(
              title=title,
              datasource='$datasource',
              graphMode='none',
              unit=unit,
            )
            .addTarget(prometheus.target(expr))
            .addThreshold({ color: $._config.grafanaDashboards.color.white, value: null });

          local usedCoresPanel(host) =
            valueStatPanel(
              title='Used Cores',
              expr='(1 - (avg(irate(node_cpu_seconds_total{cluster=~"$cluster", job=~"%(job)s", mode="idle"}[5m])))) * count(node_cpu_seconds_total{cluster=~"$cluster", job=~"%(job)s", mode="system"})' % { job: host.jobName },
            );

          local totalCoresPanel(host) =
            valueStatPanel(
              title='Total Cores',
              expr='count(node_cpu_seconds_total{cluster=~"$cluster", job=~"%(job)s", mode="system"})' % { job: host.jobName },
            );

          local usedRAMPanel(host) =
            valueStatPanel(
              title='Used',
              expr='sum(node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"%(job)s"}) * (((1 - sum(node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"%(job)s"}) / sum(node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"%(job)s"}))))' % { job: host.jobName },
              unit='bytes',
            );

          local totalRAMPanel(host) =
            valueStatPanel(
              title='Total',
              expr='sum(node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"%(job)s"})' % { job: host.jobName },
              unit='bytes',
            );

          local usedDiskPanel(host) =
            valueStatPanel(
              title='Used',
              expr='sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"%(job)s", device!="rootfs"}) * ((\navg(\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"%(job)s", device!="rootfs"}) by (device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"%(job)s", device!="rootfs"}) by (device)) /\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"%(job)s", device!="rootfs"}) by (device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"%(job)s", device!="rootfs"}) by (device) +\nsum(node_filesystem_avail_bytes{cluster=~"$cluster", job=~"%(job)s", device!="rootfs"}) by (device)  > 0 )\n)))' % { job: host.jobName },
              unit='bytes',
            );

          local totalDiskPanel(host) =
            valueStatPanel(
              title='Total',
              expr='sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"%(job)s", device!="rootfs"})' % { job: host.jobName },
              unit='bytes',
            );

          local applicationPanel(app, templates, index, appGridY) =
            [
              local appItemGridX =
                if std.objectHas(template, 'grid') && std.objectHas(template.grid, 'posX') then
                  template.grid.posX * 4  // `4` -> stat panel weight
                else
                  index * 4;
              local appItemGridY =
                if std.objectHas(template, 'grid') && std.objectHas(template.grid, 'posY') then
                  appGridY + (template.grid.posY * 3) + 1  // `appGridY` -> init Y position in application row; `3` -> stat panel height
                else
                  appGridY; //+(index * 3)+1

              statPanel.new(
                title='Health %s %s' % [app.name, template.name],
                description=app.description,
                datasource='$datasource',
                colorMode='background',
                unit=if std.objectHas($._config.templates, template.name) && std.objectHas($._config.templates[template.name], 'unit') then $._config.templates[template.name].unit else 'percent',
              )
              .addTarget(prometheus.target(
                if std.objectHas($._config.templates, template.name) then
                  $._config.templates[template.name].expr % { job: 'job=~"%s"' % app.jobName }
                else
                  $._config.templates.defaultApp.expr % { job: 'job=~"%s"' % app.jobName }
              ))
              .addDataLink({ title: 'Detail', url: '/d/%s?var-job=%s&%s' % [$._config.grafanaDashboards.ids[template.name], app.jobName, $._config.grafanaDashboards.dataLinkCommonArgs] })
              .addThresholds(
                if std.objectHas($._config.templates, template.name) then
                  $.grafanaThresholds($._config.templates[template.name].thresholds)
                else
                  $.grafanaThresholds($._config.templates.defaultApp.thresholds)
              )
              { gridPos: { x: appItemGridX, y: appItemGridY, w: 4, h: 3 } }

              for template in templates
            ];

          local hostPanel(host, apps, gridY) =
            local rowGridY = gridY;
            local textGridY = rowGridY + 1;
            local overallGridY = textGridY + 1;
            local usedTotalGridY = overallGridY + 3;
            local appGridY = usedTotalGridY + 2;
            [
              row.new('Host %s' % host.name) { gridPos: { x: 0, y: rowGridY, w: 24, h: 1 } },
              text.new('CPU') { gridPos: { x: 0, y: textGridY, w: 6, h: 1 } },
              text.new('RAM') { gridPos: { x: 6, y: textGridY, w: 6, h: 1 } },
              text.new('Disk') { gridPos: { x: 12, y: textGridY, w: 6, h: 1 } },
              text.new('Network') { gridPos: { x: 18, y: textGridY, w: 6, h: 1 } },
              overallUtilizationCPUPanel(host) { gridPos: { x: 0, y: overallGridY, w: 6, h: 3 } },
              overallUtilizationRAMPanel(host) { gridPos: { x: 6, y: overallGridY, w: 6, h: 3 } },
              overallUtilizationDiskPanel(host) { gridPos: { x: 12, y: overallGridY, w: 6, h: 3 } },
              networkErrorsPanel(host) { gridPos: { x: 18, y: overallGridY, w: 6, h: 3 } },
              usedCoresPanel(host) { gridPos: { x: 0, y: usedTotalGridY, w: 3, h: 2 } },
              totalCoresPanel(host) { gridPos: { x: 3, y: usedTotalGridY, w: 3, h: 2 } },
              usedRAMPanel(host) { gridPos: { x: 6, y: usedTotalGridY, w: 3, h: 2 } },
              totalRAMPanel(host) { gridPos: { x: 9, y: usedTotalGridY, w: 3, h: 2 } },
              usedDiskPanel(host) { gridPos: { x: 12, y: usedTotalGridY, w: 3, h: 2 } },
              totalDiskPanel(host) { gridPos: { x: 15, y: usedTotalGridY, w: 3, h: 2 } },
            ] +
            (if std.length(apps) > 0 then [text.new('Applications') { gridPos: { x: 0, y: appGridY, w: 24, h: 1 } }] else []) +
            (if std.length(apps) > 0 then std.flattenArrays([
               applicationPanel(index_app[1], index_app[1].templates, index_app[0], appGridY + 1)
               for index_app in zipWithIndex(apps)
             ]) else []);

          local hostPanels =
            std.flattenArrays([
              hostPanel(
                index_host[1],
                if std.objectHas(index_host[1], 'apps') then index_host[1].apps else [],
                getGridY(index_host[0], $._config.hostMonitoring.hosts)
              )
              for index_host in zipWithIndex($._config.hostMonitoring.hosts)
            ]);

          local isAppMonitoring =
            std.length($._config.appMonitoring.apps) > 0 && $._config.appMonitoring.enabled;

          dashboard.new(
            'Host Monitoring',
            editable=$._config.grafanaDashboards.editable,
            graphTooltip=$._config.grafanaDashboards.tooltip,
            refresh=$._config.grafanaDashboards.refresh,
            time_from=$._config.grafanaDashboards.time_from,
            tags=$._config.grafanaDashboards.tags.k8sHostsMain,
            uid=$._config.grafanaDashboards.ids.hostMonitoring,
          )
          .addLinks(
            (if isAppMonitoring then [appMonitoringLink] else []) + [k8sMonitoringLink, dNationLink]
          )
          .addTemplates([datasourceTemplate, alertManagerTemplate, clusterTemplate])
          .addPanels(
            [
              row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
              criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
              warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
            ] + hostPanels
          ),
      } else {},
}
