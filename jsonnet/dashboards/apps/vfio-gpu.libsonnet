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

/* VFIO exporter dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local statPanel = grafana.panel.stat;
local gaugePanel = grafana.panel.gauge;
local prometheus = grafana.query.prometheus;
local inUseGPUQuery = 'max( label_replace(node_vfio_gpu_in_use_count{cluster="$cluster"}, "node_ip", "$1", "instance", "([^:]+)(:.*)?") * on(node_ip) group_left(nodename) label_replace(node_uname_info{cluster="$cluster",nodename="$instance"}, "node_ip", "$1", "instance", "([^:]+)(:.*)?") )';
local totalGPUQuery = 'max(label_replace(node_vfio_gpu_total_count{cluster="$cluster"}, "node_ip", "$1", "instance", "([^:]+)(:.*)?") * on(node_ip) group_left(nodename) label_replace(node_uname_info{cluster="$cluster",nodename="$instance"}, "node_ip", "$1", "instance", "([^:]+)(:.*)?"))';
local percentGPUQuery = '(' + inUseGPUQuery + '/' + totalGPUQuery + ')*100';
local instanceQuery = 'query_result(node_uname_info and on(instance) node_vfio_gpu_total_count >0)';
local instanceRegex = '/.nodename="([^"]+)"./';

{
  grafanaDashboards+:: {
    'vfio-gpu':
      local color = $._config.grafanaDashboards.color;

      local promTarget(expr, legendFormat) =
        prometheus.withExpr(expr) + prometheus.withInstant(true) + prometheus.withLegendFormat(legendFormat);

      local vfioGPUusage =
        statPanel.new('$instance')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit('none')
        + statPanel.options.withColorMode('value')
        + statPanel.options.withGraphMode('none')
        + statPanel.options.reduceOptions.withCalcs(['mean'])
        + statPanel.panelOptions.withRepeat('instance')
        + statPanel.panelOptions.withRepeatDirection('h')
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps([{ color: color.blue, value: 0 }])
        + statPanel.queryOptions.withTargets([
          promTarget(inUseGPUQuery, 'In Use'),
          promTarget(totalGPUQuery, 'Total'),
        ]);

      local vfioPercentage =
        gaugePanel.new('$instance')
        + gaugePanel.queryOptions.withDatasource('prometheus', '$datasource')
        + gaugePanel.standardOptions.withUnit('%')
        + gaugePanel.standardOptions.withMin(0)
        + gaugePanel.standardOptions.withMax(100)
        + gaugePanel.options.reduceOptions.withCalcs(['mean'])
        + gaugePanel.panelOptions.withRepeat('instance')
        + gaugePanel.panelOptions.withRepeatDirection('h')
        + gaugePanel.standardOptions.thresholds.withMode('absolute')
        + gaugePanel.standardOptions.thresholds.withSteps([
          { color: color.green, value: 0 },
          { color: color.orange, value: 75 },
          { color: color.red, value: 90 },
        ])
        + gaugePanel.queryOptions.withTargets([
          promTarget(percentGPUQuery, 'Usage'),
        ]);

      dashboard.new('Vfio GPU Devices')
      + dashboard.withUid($._config.grafanaDashboards.ids.vfioGPU)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.instanceTemplate(instanceQuery, regex=instanceRegex),
      ])
      + dashboard.withPanels([
        vfioGPUusage { gridPos: { x: 0, y: 0, w: 18, h: 8 } },
        vfioPercentage { gridPos: { x: 0, y: 8, w: 18, h: 12 } },
      ]),
  },
}
