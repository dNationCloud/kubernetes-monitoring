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
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local variable = dashboard.variable;
local timeSeriesPanel = grafana.panel.timeSeries;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    'network-namespace-overview':
      local resolutionTemplate =
        variable.interval.new('resolution', ['30s', '5m', '1h'])
        + variable.interval.generalOptions.withLabel('Resolution')
        + variable.interval.generalOptions.withCurrent('5m');

      local intervalTemplate =
        variable.interval.new('interval', ['4h'])
        + variable.interval.generalOptions.withLabel('Interval')
        + variable.interval.generalOptions.withCurrent('4h')
        + { hide: 2 };

      local timeSeriesStacked(title, expr, unit='pps') =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.standardOptions.withUnit(unit)
        + timeSeriesPanel.standardOptions.withMin(0)
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(20)
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(false)
        + timeSeriesPanel.options.legend.withDisplayMode('table')
        + timeSeriesPanel.options.legend.withPlacement('right')
        + timeSeriesPanel.options.legend.withCalcs(['mean', 'lastNotNull', 'max', 'min'])
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc')
        + timeSeriesPanel.queryOptions.withTargets([prometheus.withExpr(expr) + prometheus.withLegendFormat('{{namespace}}')]);

      local recPackErrGraphPanel = timeSeriesStacked('Rate of Received Packets Errors', 'sort_desc(sum(irate(node_network_receive_errs_total{cluster="$cluster", namespace=~".+", device!~"lo | veth. | docker.* | flannel.* | cali.* | cbr."}[$interval:$resolution])) by (namespace))');
      local transPackErrGraphPanel = timeSeriesStacked('Rate of Transmitted Packets Errors', 'sort_desc(sum(irate(node_network_transmit_errs_total{cluster="$cluster", namespace=~".+", device!~"lo | veth. | docker.* | flannel.* | cali.* | cbr."}[$interval:$resolution])) by (namespace))');
      local recPackDropGraphPanel = timeSeriesStacked('Rate of Received Packets Dropped', 'sort_desc(sum(irate(container_network_receive_packets_dropped_total{cluster="$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))');
      local transPackDropGraphPanel = timeSeriesStacked('Rate of Transmitted Packets Dropped', 'sort_desc(sum(irate(container_network_transmit_packets_dropped_total{cluster="$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))');
      local recBandGraphPanel = timeSeriesStacked('Receive Bandwidth', 'sort_desc(sum(irate(container_network_receive_bytes_total{cluster="$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))', 'Bps');
      local transBandGraphPanel = timeSeriesStacked('Transmit Bandwidth', 'sort_desc(sum(irate(container_network_transmit_bytes_total{cluster="$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))', 'Bps');
      local recPackGraphPanel = timeSeriesStacked('Rate of Received Packets', 'sort_desc(sum(irate(container_network_receive_packets_total{cluster="$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))');
      local transPackGraphPanel = timeSeriesStacked('Rate of Transmitted Packets', 'sort_desc(sum(irate(container_network_transmit_packets_total{cluster="$cluster", namespace=~".+"}[$interval:$resolution])) by (namespace))');

      dashboard.new('Network per Namespace')
      + dashboard.withUid($._config.grafanaDashboards.ids.networkNamespaceOverview)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sOverview)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        intervalTemplate,
        resolutionTemplate,
      ])
      + dashboard.withPanels([
        row.new('Errors') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        recPackErrGraphPanel { gridPos: { x: 0, y: 1, w: 24, h: 9 } },
        transPackErrGraphPanel { gridPos: { x: 0, y: 10, w: 24, h: 9 } },
        row.new('Drops') + { gridPos: { x: 0, y: 19, w: 24, h: 1 } },
        recPackDropGraphPanel { gridPos: { x: 0, y: 20, w: 24, h: 9 } },
        transPackDropGraphPanel { gridPos: { x: 0, y: 29, w: 24, h: 9 } },
        row.new('Bandwidth') + { gridPos: { x: 0, y: 38, w: 24, h: 1 } },
        recBandGraphPanel { gridPos: { x: 0, y: 39, w: 24, h: 9 } },
        transBandGraphPanel { gridPos: { x: 0, y: 48, w: 24, h: 9 } },
        row.new('Packets') + { gridPos: { x: 0, y: 57, w: 24, h: 1 } },
        recPackGraphPanel { gridPos: { x: 0, y: 58, w: 24, h: 9 } },
        transPackGraphPanel { gridPos: { x: 0, y: 67, w: 24, h: 9 } },
      ]),
  },
}
