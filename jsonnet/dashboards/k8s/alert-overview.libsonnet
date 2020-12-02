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

/* K8s alert overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'alert-overview':
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

      local alertGroup =
        template.new(
          datasource='$alertmanager',
          query='label_values(ALERTS, alertgroup)',
          refresh=$._config.grafanaDashboards.templateRefresh,
          name='alertgroup',
          label='Alert Group',
          multi=true,
          includeAll=true,
        );

      local severityTemplate =
        template.new(
          datasource='$alertmanager',
          query='label_values(ALERTS, severity)',
          refresh=$._config.grafanaDashboards.templateRefresh,
          name='severity',
          label='Severity',
          multi=true,
          includeAll=true,
        );

      local colors = [$._config.grafanaDashboards.color.green, $._config.grafanaDashboards.color.orange, $._config.grafanaDashboards.color.red];

      local valueMaps =
        [
          { text: 'Critical', value: 4 },
          { text: 'Warning', value: 2 },
          { text: 'Info', value: 1 },
        ];

      local thresholds = [2, 4];

      local alertsInfoTable =
        table.new(
          title='Alerts Info',
          datasource='$alertmanager',
          styles=[
            { alias: 'Starts At', pattern: 'Time', type: 'date' },
            { alias: 'Severity', pattern: 'severity', colors: colors, colorMode: 'row', type: 'string', thresholds: thresholds, valueMaps: valueMaps, mappingType: 1 },
            { alias: 'Alertname', pattern: 'alertname', type: 'string' },
            { alias: 'Job', pattern: 'job', type: 'string' },
            { alias: 'Node', pattern: 'nodename', type: 'string' },
            { pattern: 'prometheus', type: 'hidden' },
            { alias: 'Message', pattern: 'message', type: 'string' },
          ]
        )
        .addTarget({ type: 'table', expr: 'ALERTS{alertname!="Watchdog", severity=~"$severity", alertgroup=~"$alertgroup"}' });

      dashboard.new(
        'Alert',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.alertOverview,
      )
      .addTemplates([datasourceTemplate, alertManagerTemplate, alertGroup, severityTemplate])
      .addPanels(
        [
          row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          alertsInfoTable { gridPos: { x: 0, y: 1, w: 24, h: 22 } },
        ]
      ),
  },
}
