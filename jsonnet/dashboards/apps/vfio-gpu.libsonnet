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
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local statPanel = grafana.statPanel;
local gaugePanel = grafana.gaugePanel;
local inUseGPUQuery='max( label_replace(node_vfio_gpu_in_use_count{cluster="$cluster"}, "node_ip", "$1", "instance", "([^:]+)(:.*)?") * on(node_ip) group_left(nodename) label_replace(node_uname_info{cluster="$cluster",nodename="$instance"}, "node_ip", "$1", "instance", "([^:]+)(:.*)?") )';
local totalGPUQuery='max(label_replace(node_vfio_gpu_total_count{cluster="$cluster"}, "node_ip", "$1", "instance", "([^:]+)(:.*)?") * on(node_ip) group_left(nodename) label_replace(node_uname_info{cluster="$cluster",nodename="$instance"}, "node_ip", "$1", "instance", "([^:]+)(:.*)?"))';
local percentGPUQuery='('+inUseGPUQuery+'/'+totalGPUQuery+')*100';
local instanceQuery='query_result(node_uname_info and on(instance) node_vfio_gpu_total_count >0)';
local instanceRegex='/.nodename="([^"]+)"./';

{
  grafanaDashboards+:: {
    'vfio-gpu':
    local vfioGPUusage =
    statPanel.new(
        title='$instance',
        datasource='$datasource',
        graphMode='none',
        repeat='instance',
    )
    .addTarget(
        prometheus.target(
            expr=inUseGPUQuery,
            instant=true,
            legendFormat="In Use",
       )
    )
    .addThreshold({ value: 0, color: $._config.grafanaDashboards.color.blue })
    .addTarget(
        prometheus.target(
        expr=totalGPUQuery,
        instant=true,
        legendFormat="Total",
        )
    );
    local vfioPercentage =
    gaugePanel.new(
        title="$instance",
        datasource='$datasource',
        min=0,
        max=100,
        repeat='instance',
        unit='%',
    )
    .addThreshold({ value: 0, color: $._config.grafanaDashboards.color.green })
    .addThreshold({ value: 75, color: $._config.grafanaDashboards.color.orange})
    .addThreshold({ value: 90, color: $._config.grafanaDashboards.color.red })
    .addTarget(
        prometheus.target(
            expr=percentGPUQuery,
            instant=true,
            legendFormat='Usage'
        )
    );
   dashboard.new(
        'Vfio GPU Devices',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.vfioGPU,
   )
   .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.instanceTemplate(query=instanceQuery, regex=instanceRegex)
   ])
   .addPanels([
    vfioGPUusage {gridPos: {x:0,y:0,w:18,h:8}},
    vfioPercentage{gridPos: {x:0,y:8,w:18,h:12}}
    ])
 }
}
