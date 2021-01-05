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

/* K8s memory overview dashboard */

local grafana = (import 'grafonnet/grafana.libsonnet')
                + (import 'grafonnet-polystat-panel/plugin.libsonnet');
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local graphPanel = grafana.graphPanel;
local polystatPanel = grafana.polystatPanel;

{
  grafanaDashboards+:: {
    'memory-overview':
      local datasourceTemplate =
        template.datasource(
          name='datasource',
          label='Datasource',
          query='prometheus',
          current=null,
        );

      local instanceTemplate =
        template.new(
          name='instance',
          label='Nodes',
          query='label_values(node_uname_info{cluster=~"$cluster", job=~"$job"}, nodename)',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          multi=true,
          includeAll=true,
        );

      local jobTemplate =
        template.new(
          name='job',
          query='label_values(node_exporter_build_info{cluster=~"$cluster", pod!~""}, job)',
          label='Job',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      local clusterTemplate =
        template.new(
          name='cluster',
          query='label_values(node_uname_info, cluster)',
          label='Cluster',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      local polystatThresholds =
        [
          { color: $._config.grafanaDashboards.color.green, state: 0, value: 0 },
          { color: $._config.grafanaDashboards.color.orange, state: 1, value: 75 },
          { color: $._config.grafanaDashboards.color.red, state: 2, value: 90 },
        ];

      local memPerNodePolystat =
        polystatPanel.new(
          title='Memory per Node',
          datasource='$datasource',
          description='The percentage of the memory utilization is calculated by:\n```\n1 - (<memory available>/<memory total>)\n```',
          default_click_through='/d/%s?var-job=$job&var-instance=${__cell_name}&%s' % [$._config.grafanaDashboards.ids.nodeExporter, $._config.grafanaDashboards.dataLinkCommonArgs],
          global_unit_format='percent',
          global_thresholds=polystatThresholds,
          hexagon_sort_by_direction=2,
          hexagon_sort_by_field='value',
          polygon_border_size=0,
          tooltip_timestamp_enabled=false,
        )
        {
          polystat+: {
            globalDecimals: null,
            fontAutoColor: false,
            fontColor: $._config.grafanaDashboards.color.white,
          },
        }
        .addTarget(prometheus.target(legendFormat='{{nodename}}', expr='round((1 - (sum(node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"$job"}) by (instance) / sum(node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}) by (instance) )) * 100)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'));

      local memUtilGraphPanel =
        graphPanel.new(
          title='Memory Utilization',
          description='The used memory is calculated by:\n```\n<memory total> - <memory available>\n```',
          datasource='$datasource',
          format='bytes',
          min=0,
        )
        .addSeriesOverride({ alias: '/total/', color: '#C4162A', fill: 0, linewidth: 2 })
        .addSeriesOverride({ alias: '/available/', hiddenSeries: true })
        .addSeriesOverride({ alias: '/buffers/', hiddenSeries: true })
        .addSeriesOverride({ alias: '/cached/', hiddenSeries: true })
        .addSeriesOverride({ alias: '/free/', hiddenSeries: true })
        .addTargets(
          [
            prometheus.target(legendFormat='memory used', expr='sum by (nodename) (node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}) - sum by (nodename) (node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"$job"} * on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='memory available', expr='sum by (nodename) (node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='memory buffers', expr='sum by (nodename) (node_memory_Buffers_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='memory cached', expr='sum by (nodename) (node_memory_Cached_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='memory free', expr='sum by (nodename) (node_memory_MemFree_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
            prometheus.target(legendFormat='memory total', expr='sum by (nodename) (node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"})'),
          ]
        );

      dashboard.new(
        'Memory per Node',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.memoryOverview,
      )
      .addTemplates([datasourceTemplate, instanceTemplate, jobTemplate, clusterTemplate])
      .addPanels(
        [
          memPerNodePolystat { gridPos: { x: 0, y: 0, w: 24, h: 6 } },
          row.new('$instance', repeat='instance', collapse=true) { gridPos: { x: 0, y: 6, w: 24, h: 1 } }
          .addPanel(memUtilGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 7, w: 24, h: 7 })
        ]
      ),
  },
}
