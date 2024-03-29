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

/* K8s apache dashboard */
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    apache:
      local requests =
        graphPanel.new(
          title='Apache Requests per second',
          datasource='$datasource',
          stack=true,
          nullPointMode='null as zero',
        )
        .addTarget(prometheus.target('rate(apache__req_per_sec{cluster="$cluster", job=~"$job"}[5m])', legendFormat='requests'));

      local cpuLoad =
        graphPanel.new(
          title='Apache CPU Load',
          datasource='$datasource',
          stack=true,
          nullPointMode='null as zero',
        )
        .addTarget(prometheus.target('rate(apache__c_p_u_load{cluster="$cluster", job=~"$job"}[5m])', legendFormat='load'));

      local memoryUtilization =
        graphPanel.new(
          title='Apache Memory Utilization',
          datasource='$datasource',
          format='bytes',
          stack=true,
          nullPointMode='null as zero',
        )
        .addTarget(prometheus.target('rate(apache__total_k_bytes_total{cluster="$cluster", job=~"$job"}[5m])', legendFormat='total'));

      local memoryUtilizationPer =
        graphPanel.new(
          title='Apache Memory Utilization per Sec/Req',
          datasource='$datasource',
          format='bytes',
          stack=true,
          nullPointMode='null as zero',
        )
        .addTargets(
          [
            prometheus.target('rate(apache__bytes_per_sec{cluster="$cluster", job=~"$job"}[5m])', legendFormat='bytes per sec'),
            prometheus.target('rate(apache__bytes_per_req{cluster="$cluster", job=~"$job"}[5m])', legendFormat='bytes per req'),
          ],
        );

      local workers =
        graphPanel.new(
          title='Apache Workers',
          datasource='$datasource',
        )
        .addTargets(
          [
            prometheus.target('rate(apache__idle_workers{cluster="$cluster", job=~"$job"}[5m])', legendFormat='idle'),
            prometheus.target('rate(apache__busy_workers{cluster="$cluster", job=~"$job"}[5m])', legendFormat='busy'),
          ],
        );

      local panels = [
        row.new('Requests') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        requests { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 1, w: 24, h: 7 } },
        row.new('CPU Load', collapse=true) { gridPos: { x: 0, y: 8, w: 24, h: 1 } }
        .addPanel(cpuLoad { tooltip+: { sort: 2 } }, { x: 0, y: 9, w: 24, h: 7 }),
        row.new('Memory Utilization', collapse=true) { gridPos: { x: 0, y: 9, w: 24, h: 1 } }
        .addPanel(memoryUtilization { tooltip+: { sort: 2 } }, { x: 0, y: 10, w: 12, h: 7 })
        .addPanel(memoryUtilizationPer { tooltip+: { sort: 2 } }, { x: 12, y: 10, w: 12, h: 7 }),
        row.new('Workers') { gridPos: { x: 0, y: 10, w: 24, h: 1 } },
        workers { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 11, w: 24, h: 7 } },
      ];

      dashboard.new(
        'Apache',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.apache,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(apache__c_p_u_load{cluster="$cluster"}, job)'),
      ])
      .addPanels(panels),
  },
}
