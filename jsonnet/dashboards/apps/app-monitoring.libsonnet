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

/* Application main dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local statPanel = grafana.statPanel;
local template = grafana.template;
local row = grafana.row;
local link = grafana.link;

local zipWithIndex(arr) =
  /**
   * Enumarate array elements.
   *
   * @param arrays The input array.
   * @return indexed array.
   */
  std.makeArray(std.length(arr), function(i) [i, arr[i]]);

{
  grafanaDashboards+::
    if std.length([$._config.appMonitoring.apps]) > 0 && $._config.appMonitoring.enabled then
      {
        'app-monitoring':
          local hostMonitoringLink =
            link.dashboards(
              title='Host Monitoring',
              tags=[],
              url='/d/%s' % $._config.grafanaDashboards.ids.hostMonitoring,
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
              expr='ALERTS{alertname!="Watchdog", severity="critical", alertgroup="%s"}' % $._config.prometheusRules.alertGroupApp,
            )
            .addDataLink({ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertOverview, $._config.prometheusRules.alertGroupApp, $._config.grafanaDashboards.dataLinkCommonArgs] })
            .addThresholds($.grafanaThresholds($._config.commonThresholds.criticalPanel));

          local warningPanel =
            alertPanel(
              title='Warning',
              expr='ALERTS{alertname!="Watchdog", severity="warning", alertgroup="%s"}' % $._config.prometheusRules.alertGroupApp,
            )
            .addDataLink({ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertOverview, $._config.prometheusRules.alertGroupApp, $._config.grafanaDashboards.dataLinkCommonArgs] })
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

          local applicationPanel(app, templates, index) =
            [
              local appGridX =
                if std.objectHas(template, 'grid') && std.objectHas(template.grid, 'posX') then
                  template.grid.posX * 4  // `4` -> stat panel weight
                else
                  index * 4;
              local appGridY =
                if std.objectHas(template, 'grid') && std.objectHas(template.grid, 'posY') then
                  5 + (template.grid.posY * 3) + 1  // `5` -> init Y position in application row; `3` -> stat panel height
                else
                  5 + (index * 3) + 1;

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
              { gridPos: { x: appGridX, y: appGridY, w: 4, h: 3 } }

              for template in templates
            ];

          local applicationPanels =
            std.flattenArrays([
              applicationPanel(index_app[1], index_app[1].templates, index_app[0])
              for index_app in zipWithIndex($._config.appMonitoring.apps)
            ]);

          local isHostMonitoring =
            std.length([$._config.hostMonitoring.hosts]) > 0 && $._config.hostMonitoring.enabled;

          dashboard.new(
            'Application Monitoring',
            editable=$._config.grafanaDashboards.editable,
            graphTooltip=$._config.grafanaDashboards.tooltip,
            refresh=$._config.grafanaDashboards.refresh,
            time_from=$._config.grafanaDashboards.time_from,
            tags=$._config.grafanaDashboards.tags.k8sAppsMain,
            uid=$._config.grafanaDashboards.ids.appMonitoring,
          )
          .addLinks(
            (if isHostMonitoring then [hostMonitoringLink] else []) + [k8sMonitoringLink, dNationLink]
          )
          .addTemplates([datasourceTemplate, alertManagerTemplate, clusterTemplate])
          .addPanels(
            [
              row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
              criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
              warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
              row.new('Applications') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
            ] + applicationPanels
          ),
      } else {},
}
