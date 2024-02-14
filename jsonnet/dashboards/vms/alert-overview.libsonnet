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

/* VM alert overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;
local dashboard = grafana.dashboard;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'alert-vm-overview':

      local colors = [$._config.grafanaDashboards.color.green, $._config.grafanaDashboards.color.orange, $._config.grafanaDashboards.color.red];
      local warning_thresholds = [2, 3];
      local critical_thresholds = [3, 3];

      local alertsInfoTable =
        table.new(
          title='Alerts Info',
          datasource='$datasource',
          styles=[
            { alias: 'Starts At', pattern: 'Time', type: 'date' },
            { alias: 'Alertname', pattern: 'alertname', type: 'string' },
            { alias: 'Job', pattern: 'job', type: 'string' },
            { alias: 'Node', pattern: 'nodename', type: 'string' },
            { alias: 'warningCode', pattern: 'Value #A', type: 'number', thresholds: warning_thresholds, colors: colors, colorMode: 'row' },
            { alias: 'criticalCode  ', pattern: 'Value #B', type: 'number', thresholds: critical_thresholds, colors: colors, colorMode: 'row' },
          ]
        )
        .addTargets([
          prometheus.target('ALERTS{job=~"$job", alertname!="Watchdog", alertstate=~"firing", severity="warning", severity=~"$severity", alertgroup=~"$alertgroup"} * 2', format='table', instant=true),
          prometheus.target('ALERTS{job=~"$job", alertname!="Watchdog", alertstate=~"firing", severity="critical", severity=~"$severity", alertgroup=~"$alertgroup"} * 3', format='table', instant=true),
        ])
        .addTransformations([
          {
            id: 'organize',
            options: {
              excludeByName: {
                __name__: true,
                prometheus: true,
              },
              indexByName: {
                Time: 0,
                severity: 1,
                nodename: 2,
                alertname: 3,
                job: 4,
                alertstate: 4,
                alertgroup: 5,
              },
            },
          },
          {
            id: 'seriesToRows',
          },
        ]);

      dashboard.new(
        'AlertVM',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.alertVMOverview,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.alertManagerTemplate(),
        $.grafanaTemplates.alertGroupTemplate('label_values(ALERTS, alertgroup)'),
        $.grafanaTemplates.severityTemplate('label_values(ALERTS, severity)'),
        $.grafanaTemplates.jobTemplate('label_values(ALERTS, job)', hide='variable'),
      ])
      .addPanels(
        [
          row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          alertsInfoTable { gridPos: { x: 0, y: 1, w: 24, h: 22 } },
        ]
      ),
  },
}
