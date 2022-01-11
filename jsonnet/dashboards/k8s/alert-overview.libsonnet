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
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'alert-cluster-overview':
      local alertsInfoTable =
        table.new(
          title='Alerts Info',
          datasource='$alertmanager',
          styles=[
            { alias: 'Detailed link', pattern: 'link', type: 'string', link: true, linkUrl: '/d/${__cell:raw}&from=${__cell_0:raw}&to=now' },
            { alias: 'Runbook url', pattern: 'runbook_url', type: 'string', link: true, linkUrl: '${__cell:raw}' },
          ]
        )
        .addTransformations([
          {
            id: 'organize',
            options: {
              excludeByName: {
                alertstatus_code: true,
                prometheus: true,
              },
              indexByName: {
                Time: 0,
                severity: 1,
                alertname: 2,
                message: 3,
                link: 4,
                alertstatus: 5,
                job: 6,
              },
              renameByName: {
                Time: 'Starts At',
                nodename: 'node',
              },
            },
          },
        ])
        {
          targets: [{
            active: true,
            inhibited: true,
            filters: 'severity=~"$severity", alertgroup=~"$alertgroup"',
          }],
        };

      dashboard.new(
        'AlertCluster',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.alertClusterOverview,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.alertManagerTemplate(),
        $.grafanaTemplates.alertGroupTemplate('label_values(ALERTS, alertgroup)'),
        $.grafanaTemplates.severityTemplate('label_values(ALERTS, severity)'),
      ])
      .addPanels(
        [
          row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          alertsInfoTable { gridPos: { x: 0, y: 1, w: 24, h: 22 } },
        ]
      ),
  },
}
