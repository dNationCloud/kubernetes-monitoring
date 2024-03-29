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

/* K8s nginx nrpe dashboard */
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    'nginx-nrpe':
      local connections1 =
        graphPanel.new(
          title='Nginx connections',
          datasource='$datasource',
          stack=true,
          nullPointMode='null as zero',
        )
        .addTargets(
          [
            prometheus.target('rate(nginx_accepts_total{cluster="$cluster", job=~"$job"}[5m])', legendFormat='accepts'),
            prometheus.target('rate(nginx_handled_total{cluster="$cluster", job=~"$job"}[5m])', legendFormat='handled'),
            prometheus.target('rate(nginx_active{cluster="$cluster", job=~"$job"}[5m])', legendFormat='active'),
          ],
        );

      local connections2 =
        graphPanel.new(
          title='Nginx connections',
          datasource='$datasource',
          stack=true,
          nullPointMode='null as zero',
        )
        .addTargets(
          [
            prometheus.target('rate(nginx_reading{cluster="$cluster", job=~"$job"}[5m])', legendFormat='reading'),
            prometheus.target('rate(nginx_writing{cluster="$cluster", job=~"$job"}[5m])', legendFormat='writing'),
            prometheus.target('rate(nginx_waiting{cluster="$cluster", job=~"$job"}[5m])', legendFormat='waiting'),
          ],
        );

      local requests =
        graphPanel.new(
          title='Nginx requests',
          datasource='$datasource',
          stack=true,
          nullPointMode='null as zero',
        )
        .addTarget(prometheus.target('rate(nginx_requests_total{cluster="$cluster", job=~"$job"}[5m])', legendFormat='requests'));

      local panels = [
        row.new('Connections') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        connections1 { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 1, w: 24, h: 7 } },
        connections2 { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 8, w: 24, h: 7 } },
        row.new('Requests') { gridPos: { x: 0, y: 15, w: 24, h: 1 } },
        requests { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 16, w: 24, h: 7 } },
      ];

      dashboard.new(
        'Nginx Nrpe',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.nginxNrpe,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(nginx_accepts_total{cluster="$cluster"}, job)'),
      ])
      .addPanels(panels),
  },
}
