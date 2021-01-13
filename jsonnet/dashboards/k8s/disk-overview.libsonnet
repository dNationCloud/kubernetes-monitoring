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

/* K8s disk overview dashboard */

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
    'disk-overview':
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

      local diskPerNodePolystat =
        polystatPanel.new(
          title='Disk per Node',
          datasource='$datasource',
          description='The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition.',
          default_click_through='/d/%s?var-job=$job&var-instance=${__cell_name}&%s' % [$._config.grafanaDashboards.ids.nodeExporter, $._config.grafanaDashboards.dataLinkCommonArgs],
          global_unit_format='percent',
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
            fontColor: $._config.grafanaDashboards.color.white,
          },
        }
        .addTarget(prometheus.target(legendFormat='{{nodename}}', expr='round(\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device)) /\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device) +\nsum(node_filesystem_avail_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device))\n * 100\n) * on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'));

      local diskUtilGraphPanel =
        graphPanel.new(
          title='Disk Utilization',
          description='The value of the available disk capacity is reduced by  5%, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition.',
          datasource='$datasource',
          format='bytes',
          min=0,
        )
        .addSeriesOverride({ alias: '/size/', fill: 0, linewidth: 2 })
        .addSeriesOverride({ alias: '/available/', hiddenSeries: true })
        .addTargets(
          [
            prometheus.target(legendFormat='disk used {{device}}', expr='(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device, instance) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device, instance))\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
            prometheus.target(legendFormat='disk size {{device}}', expr='sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device, instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
            prometheus.target(legendFormat='disk available {{device}}', expr='sum(node_filesystem_avail_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device, instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          ]
        );

      local diskIOGraphPanel =
        graphPanel.new(
          title='Disk I/O',
          datasource='$datasource',
          formatY1='bytes',
          formatY2='s',
          fill=0,
        )
        .addSeriesOverride({ alias: '/read*|written*/', yaxis: 1 })
        .addSeriesOverride({ alias: '/io time*/', yaxis: 2 })
        .addTargets(
          [
            prometheus.target(legendFormat='read {{device}}', expr='sum(rate(node_disk_read_bytes_total{cluster=~"$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
            prometheus.target(legendFormat='written {{device}}', expr='sum(rate(node_disk_written_bytes_total{cluster=~"$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
            prometheus.target(legendFormat='io time {{device}}', expr='sum(rate(node_disk_io_time_seconds_total{cluster=~"$cluster", job=~"$job"}[5m])) by (instance)\n* on(instance) group_left(nodename) \n   node_uname_info{cluster=~"$cluster", nodename=~"$instance"}'),
          ]
        );

      dashboard.new(
        'Disk per Node',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.diskOverview,
      )
      .addTemplates([datasourceTemplate, instanceTemplate, jobTemplate, clusterTemplate])
      .addPanels(
        [
          diskPerNodePolystat { gridPos: { x: 0, y: 0, w: 24, h: 6 } },
          row.new('$instance', repeat='instance', collapse=true) { gridPos: { x: 0, y: 6, w: 24, h: 1 } }
          .addPanel(diskUtilGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 7, w: 24, h: 7 })
          .addPanel(diskIOGraphPanel { tooltip+: { sort: 2 } }, { x: 0, y: 14, w: 24, h: 7 }),
        ]
      ),
  },
}
