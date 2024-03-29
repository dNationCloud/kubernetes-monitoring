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

/* K8s autoscaler dashboard */
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    autoscaler:
      local managedObjects =
        graphPanel.new(
          title='Autoscaler Managed Objects',
          datasource='$datasource',
        )
        .addTargets(
          [
            prometheus.target('sum(autoscaler_instances{cluster="$cluster", job=~"$job"})', legendFormat='instances'),
            prometheus.target('sum(autoscaler_healthy{cluster="$cluster", job=~"$job"})', legendFormat='instances healthy'),
            prometheus.target('sum(autoscaler_groups{cluster="$cluster", job=~"$job"})', legendFormat='groups'),
          ],
        );

      local panels = [
        row.new('Autoscaler Managed Objects') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        managedObjects { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 1, w: 24, h: 7 } },
      ];

      dashboard.new(
        'Autoscaler',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.autoscaler,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(autoscaler_instances{cluster="$cluster"}, job)'),
      ])
      .addPanels(panels),
  },
}
