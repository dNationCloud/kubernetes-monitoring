/*
  Copyright 2020 The K8s-m8g Authors. All Rights Reserved.
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

/* K8s network overview dashboard */

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
    'network-overview':
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
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          multi=true,
          includeAll=true,
        );

      local jobTemplate =
        template.new(
          name='job',
          query='label_values(node_exporter_build_info{cluster=~"$cluster", pod!~""}, job)',
          label='Job',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local clusterTemplate =
        template.new(
          name='cluster',
          query='label_values(node_uname_info, cluster)',
          label='Cluster',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local polystatThresholds =
        [
          { color: $._config.dashboardCommon.color.green, state: 0, value: 0 },
          { color: $._config.dashboardCommon.color.orange, state: 1, value: 10 },
          { color: $._config.dashboardCommon.color.red, state: 2, value: 30 },
        ];

      local memPerNodePolystat =
        polystatPanel.new(
          title='Network Errors per Node',
          datasource='$datasource',
          default_click_through='/d/%s?var-job=$job&var-instance=${__cell_name}&%s' % [$._config.dashboardIDs.nodeExporter, $._config.dashboardCommon.dataLinkCommonArgs],
          global_unit_format='pps',
          global_thresholds=polystatThresholds,
          hexagon_sort_by_direction=4,
          hexagon_sort_by_field='value',
          polygon_border_size=0,
          tooltip_timestamp_enabled=false,
        )
        {
          polystat+: {
            globalDecimals: null,
            fontAutoColor: false,
            fontColor: $._config.dashboardCommon.color.white,
          },
        }
        .addTarget(prometheus.target(legendFormat='{{nodename}}', expr='(sum(rate(node_network_transmit_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]))  by (instance) \n   + sum(rate(node_network_receive_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])) by (instance))\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'));

      local transRecGraphPanel =
        graphPanel.new(
          title='Transmit/Receive Errors',
          datasource='$datasource',
          format='pps',
          fill=0,
        )
        .addSeriesOverride({ alias: '/Rx_/', stack: 'B', transform: 'negative-Y' })
        .addSeriesOverride({ alias: '/Tx_/', stack: 'A' })
        .addTargets(
          [
            prometheus.target(legendFormat='Tx_{{device}}', expr='rate(node_network_transmit_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
            prometheus.target(legendFormat='Rx_{{device}}', expr='rate(node_network_receive_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          ]
        );

      local netRecGraphPanel =
        graphPanel.new(
          title='Network Received',
          datasource='$datasource',
          format='bytes',
          fill=0,
          min=0,
        )
        .addTarget(prometheus.target(legendFormat='{{device}}', expr='rate(node_network_receive_bytes_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'));

      local netTransGraphPanel =
        graphPanel.new(
          title='Network Transmitted',
          datasource='$datasource',
          format='bytes',
          fill=0,
          min=0,
        )
        .addTarget(prometheus.target(legendFormat='{{device}}', expr='rate(node_network_transmit_bytes_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'));

      dashboard.new(
        'Network per Node',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sOverview,
        uid=$._config.dashboardIDs.networkOverview,
      )
      .addTemplates([datasourceTemplate, instanceTemplate, jobTemplate, clusterTemplate])
      .addPanels(
        [
          memPerNodePolystat { gridPos: { x: 0, y: 0, w: 24, h: 6 } },
          row.new('$instance', repeat='instance', collapse=true) { gridPos: { x: 0, y: 6, w: 24, h: 1 } }
          .addPanel(transRecGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 7, w: 8, h: 7 })
          .addPanel(netRecGraphPanel { tooltip+: { sort: 2 } }, { x: 8, y: 7, w: 8, h: 7 })
          .addPanel(netTransGraphPanel { tooltip+: { sort: 2 } }, { x: 16, y: 7, w: 8, h: 7 }),
        ]
      ),
  },
}
