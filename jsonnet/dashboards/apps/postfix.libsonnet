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

/* K8s postfix dashboard */
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local row = grafana.row;

{
  grafanaDashboards+:: {
    postfix:
      local queueSize =
        graphPanel.new(
          title='Postfix Queue Size',
          datasource='$datasource',
          stack=true,
          nullPointMode='null as zero',
        )
        .addTarget(prometheus.target('sum(postfix_size{cluster="$cluster", job=~"$job"})', legendFormat='queue size'));

      local panels = [
        row.new('Queue Size') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        queueSize { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 1, w: 24, h: 7 } },
      ];

      dashboard.new(
        'Postfix',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.postfix,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(postfix_size{cluster="$cluster"}, job)'),
      ])
      .addPanels(panels),
  },
}
