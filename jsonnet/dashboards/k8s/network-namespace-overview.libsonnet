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

/* K8s network namespace overview dashboard */

local grafana = (import 'grafonnet/grafana.libsonnet');
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local graphPanel = grafana.graphPanel;

{
  grafanaDashboards+:: {
    'network-namespace-overview':
      local datasourceTemplate =
        template.datasource(
          name='datasource',
          label='Datasource',
          query='prometheus',
          current=null,
        );

      local resolutionTemplate =
        template.interval(
          name='resolution',
          label='Resolution',
          query='30s,5m,1h',
          current='5m',
        );

      local intervalTemplate =
        template.interval(
          name='interval',
          label='Interval',
          query='4h',
          current='4h',
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

      local networkPanel(title, format='pps', expr) =
        graphPanel.new(
          title=title,
          datasource='$datasource',
          format=format,
          min=0,
          stack=true,
          fill=2,
          linewidth=2,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_current=true,
          legend_max=true,
          legend_min=true,
          legend_values=true,
          legend_rightSide=true,
          legend_hideEmpty=true,
          legend_hideZero=true,
        )
        .addTarget(prometheus.target(legendFormat='{{namespace}}', expr=expr));

      local recPackErrGraphPanel =
        networkPanel(
          title='Rate of Received Packets Errors',
          expr='sort_desc(sum(irate(node_network_receive_errs_total{cluster=~"$cluster", namespace=~".+", device!~"lo | veth. | docker.* | flannel.* | cali.* | cbr."}[$interval:$resolution])) by (namespace))',
        );

      local transPackErrGraphPanel =
        networkPanel(
          title='Rate of Transmitted Packets Errors',
          expr='sort_desc(sum(irate(node_network_transmit_errs_total{cluster=~"$cluster", namespace=~".+", device!~"lo | veth. | docker.* | flannel.* | cali.* | cbr."}[$interval:$resolution])) by (namespace))',
        );

      local recPackDropGraphPanel =
        networkPanel(
          title='Rate of Received Packets Dropped',
          expr='sort_desc(sum(irate(container_network_receive_packets_dropped_total{cluster=~"$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))',
        );

      local transPackDropGraphPanel =
        networkPanel(
          title='Rate of Transmitted Packets Dropped',
          expr='sort_desc(sum(irate(container_network_transmit_packets_dropped_total{cluster=~"$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))',
        );

      local recBandGraphPanel =
        networkPanel(
          title='Receive Bandwidth',
          format='Bps',
          expr='sort_desc(sum(irate(container_network_receive_bytes_total{cluster=~"$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))',
        );

      local transBandGraphPanel =
        networkPanel(
          title='Transmit Bandwidth',
          format='Bps',
          expr='sort_desc(sum(irate(container_network_transmit_bytes_total{cluster=~"$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))',
        );

      local recPackGraphPanel =
        networkPanel(
          title='Rate of Received Packets',
          expr='sort_desc(sum(irate(container_network_receive_packets_total{cluster=~"$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))',
        );

      local transPackGraphPanel =
        networkPanel(
          title='Rate of Transmitted Packets',
          expr='sort_desc(sum(irate(container_network_transmit_packets_total{cluster=~"$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))',
        );

      dashboard.new(
        'Network per Namespace',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.networkNamespaceOverview,
      )
      .addTemplates([datasourceTemplate, resolutionTemplate, intervalTemplate, clusterTemplate])
      .addPanels(
        [
          row.new('Errors') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          recPackErrGraphPanel { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 1, w: 24, h: 9 } },
          transPackErrGraphPanel { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 10, w: 24, h: 9 } },
          row.new('Drops', collapse=true) { gridPos: { x: 0, y: 19, w: 24, h: 1 } }
          .addPanel(recPackDropGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 2, w: 24, h: 9 })
          .addPanel(transPackDropGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 11, w: 24, h: 9 }),
          row.new('Bandwidth', collapse=true) { gridPos: { x: 0, y: 20, w: 24, h: 1 } }
          .addPanel(recBandGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 3, w: 24, h: 9 })
          .addPanel(transBandGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 12, w: 24, h: 9 }),
          row.new('Packets', collapse=true) { gridPos: { x: 0, y: 21, w: 24, h: 1 } }
          .addPanel(recPackGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 4, w: 24, h: 9 })
          .addPanel(transPackGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 13, w: 24, h: 9 }),
        ]
      ),
  },
}
