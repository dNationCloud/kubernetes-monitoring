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

/* K8s api server dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;
local availabilityDays = 30;
local errorBudgetTarget = 0.99;

{
  grafanaDashboards+:: {
    'api-server':
      local availability1d =
        statPanel.new(
          title='Availability (%dd) > %.3f%%' % [availabilityDays, 100 * errorBudgetTarget],
          datasource='$datasource',
          unit='percentunit',
          decimals=3,
        )
        .addTarget(prometheus.target('apiserver_request:availability%dd{cluster=~"$cluster", verb="all"}' % availabilityDays));

      local errorBudget =
        graphPanel.new(
          title='ErrorBudget (%dd) > %.3f%%' % [availabilityDays, 100 * errorBudgetTarget],
          datasource='$datasource',
          format='percentunit',
          decimals=3,
        )
        .addTarget(prometheus.target('100 * (apiserver_request:availability%dd{cluster=~"$cluster", verb="all"} - %f)' % [availabilityDays, errorBudgetTarget], legendFormat='errorbudget'));

      local readAvailability =
        statPanel.new(
          title='Read Availability (%dd)' % availabilityDays,
          datasource='$datasource',
          unit='percentunit',
          decimals=3,
        )
        .addTarget(prometheus.target('apiserver_request:availability%dd{cluster=~"$cluster", verb="read"}' % availabilityDays));

      local readRequests =
        graphPanel.new(
          title='Read SLI - Requests',
          datasource='$datasource',
          format='reqps',
          stack=true,
        )
        .addSeriesOverride({ alias: '/2../i', color: '#56A64B' })
        .addSeriesOverride({ alias: '/3../i', color: '#F2CC0C' })
        .addSeriesOverride({ alias: '/4../i', color: '#3274D9' })
        .addSeriesOverride({ alias: '/5../i', color: '#E02F44' })
        .addTarget(prometheus.target('sum(code_resource:apiserver_request_total:rate5m{cluster=~"$cluster", verb="read"})', legendFormat='{{code}}'));

      local readErrors =
        graphPanel.new(
          title='Read SLI - Errors',
          datasource='$datasource',
          min=0,
          format='percentunit',
        )
        .addTarget(prometheus.target('sum by (resource) (code_resource:apiserver_request_total:rate5m{cluster=~"$cluster", verb="read", code=~"5.."}) / sum by (resource) (code_resource:apiserver_request_total:rate5m{cluster=~"$cluster", verb="read"})', legendFormat='{{resource}}'));

      local readDuration =
        graphPanel.new(
          title='Read SLI - Duration',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('cluster_quantile:apiserver_request_duration_seconds:histogram_quantile{cluster=~"$cluster", verb="read"}', legendFormat='{{resource}}'));

      local writeAvailability =
        statPanel.new(
          title='Write Availability (%dd)' % availabilityDays,
          datasource='$datasource',
          unit='percentunit',
          decimals=3,
        )
        .addTarget(prometheus.target('apiserver_request:availability%dd{cluster=~"$cluster", verb="write"}' % availabilityDays));

      local writeRequests =
        graphPanel.new(
          title='Write SLI - Requests',
          datasource='$datasource',
          format='reqps',
          stack=true,
        )
        .addSeriesOverride({ alias: '/2../i', color: '#56A64B' })
        .addSeriesOverride({ alias: '/3../i', color: '#F2CC0C' })
        .addSeriesOverride({ alias: '/4../i', color: '#3274D9' })
        .addSeriesOverride({ alias: '/5../i', color: '#E02F44' })
        .addTarget(prometheus.target('sum(code_resource:apiserver_request_total:rate5m{cluster=~"$cluster", verb="write"})', legendFormat='{{code}}'));

      local writeErrors =
        graphPanel.new(
          title='Write SLI - Errors',
          datasource='$datasource',
          min=0,
          format='percentunit',
        )
        .addTarget(prometheus.target('sum by (resource) (code_resource:apiserver_request_total:rate5m{cluster=~"$cluster", verb="write", code=~"5.."}) / sum by (resource) (code_resource:apiserver_request_total:rate5m{cluster=~"$cluster", verb="write"})', legendFormat='{{resource}}'));

      local writeDuration =
        graphPanel.new(
          title='Write SLI - Duration',
          datasource='$datasource',
          format='s',
        )
        .addTarget(prometheus.target('cluster_quantile:apiserver_request_duration_seconds:histogram_quantile{cluster=~"$cluster", verb="write"}', legendFormat='{{resource}}'));

      local upCount =
        statPanel.new(
          title='Up',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('sum(up{cluster=~"$cluster", %(apiServer)s})' % $._config.dashboardSelectors));

      local rpcRate =
        graphPanel.new(
          title='RPC Rate',
          datasource='$datasource',
          format='reqps',
        )
        .addTargets(
          [
            prometheus.target('sum(rate(apiserver_request_total{cluster=~"$cluster", %(apiServer)s, instance=~"$instance", code=~"2.."}[5m]))' % $._config.dashboardSelectors, legendFormat='2xx'),
            prometheus.target('sum(rate(apiserver_request_total{cluster=~"$cluster", %(apiServer)s, instance=~"$instance", code=~"3.."}[5m]))' % $._config.dashboardSelectors, legendFormat='3xx'),
            prometheus.target('sum(rate(apiserver_request_total{cluster=~"$cluster", %(apiServer)s, instance=~"$instance", code=~"4.."}[5m]))' % $._config.dashboardSelectors, legendFormat='4xx'),
            prometheus.target('sum(rate(apiserver_request_total{cluster=~"$cluster", %(apiServer)s, instance=~"$instance", code=~"5.."}[5m]))' % $._config.dashboardSelectors, legendFormat='5xx'),
          ]
        );
      local requestDuration =
        graphPanel.new(
          title='Request duration 99th quantile',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(apiserver_request_duration_seconds_bucket{cluster=~"$cluster", %(apiServer)s, instance=~"$instance", verb!="WATCH"}[5m])) by (verb, le))' % $._config.dashboardSelectors, legendFormat='5xx'));

      local workQueueAddRate =
        graphPanel.new(
          title='Work Queue Add Rate',
          datasource='$datasource',
          format='ops',
          min=0,
          legend_show=false,
        )
        .addTarget(prometheus.target('sum(rate(workqueue_adds_total{cluster=~"$cluster", %(apiServer)s, instance=~"$instance"}[5m])) by (instance, name)' % $._config.dashboardSelectors, legendFormat='{{instance}} {{name}}'));

      local workQueueDepth =
        graphPanel.new(
          title='Work Queue Depth',
          datasource='$datasource',
          min=0,
          legend_show=false,
        )
        .addTarget(prometheus.target('sum(rate(workqueue_depth{cluster=~"$cluster", %(apiServer)s, instance=~"$instance"}[5m])) by (instance, name)' % $._config.dashboardSelectors, legendFormat='{{instance}} {{name}}'));

      local workQueueLatency =
        graphPanel.new(
          title='Work Queue Latency',
          datasource='$datasource',
          format='s',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(workqueue_queue_duration_seconds_bucket{cluster=~"$cluster", %(apiServer)s, instance=~"$instance"}[5m])) by (instance, name, le))' % $._config.dashboardSelectors, legendFormat='{{instance}} {{name}}'));

      local memory =
        graphPanel.new(
          title='Memory',
          datasource='$datasource',
          format='bytes',
        )
        .addTarget(prometheus.target('process_resident_memory_bytes{cluster=~"$cluster", %(apiServer)s, instance=~"$instance"}' % $._config.dashboardSelectors, legendFormat='{{instance}}'));

      local cpu =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          min=0,
        )
        .addTarget(prometheus.target('rate(process_cpu_seconds_total{cluster=~"$cluster", %(apiServer)s, instance=~"$instance"}[5m])' % $._config.dashboardSelectors, legendFormat='{{instance}}'));

      local goroutines =
        graphPanel.new(
          title='Goroutines',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('go_goroutines{cluster=~"$cluster", %(apiServer)s, instance=~"$instance"}' % $._config.dashboardSelectors, legendFormat='{{instance}}'));

      local datasourceTemplate =
        template.datasource(
          name='datasource',
          label='Datasource',
          query='prometheus',
          current=null,
        );

      local clusterTemplate =
        template.new(
          name='cluster',
          label='Cluster',
          datasource='$datasource',
          query='label_values(apiserver_request_total, cluster)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local instanceTemplate =
        template.new(
          name='instance',
          label='Instance',
          datasource='$datasource',
          query='label_values(apiserver_request_total{cluster=~"$cluster", %(apiServer)s}, instance)' % $._config.dashboardSelectors,
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          includeAll=true,
          multi=true,
        );

      dashboard.new(
        'Api Server',
        time_from=$._config.dashboardCommon.time_from,
        uid=$._config.dashboardIDs.apiServer,
        editable=$._config.dashboardCommon.editable,
        tags=$._config.dashboardCommon.tags.k8sSystem,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
      )
      .addTemplates([datasourceTemplate, clusterTemplate, instanceTemplate])
      .addPanels(
        [
          availability1d { gridPos: { x: 0, y: 0, w: 8, h: 7 } },
          errorBudget { gridPos: { x: 8, y: 0, w: 16, h: 7 } },
          readAvailability { gridPos: { x: 0, y: 7, w: 6, h: 7 } },
          readRequests { gridPos: { x: 6, y: 7, w: 6, h: 7 } },
          readErrors { gridPos: { x: 12, y: 7, w: 6, h: 7 } },
          readDuration { gridPos: { x: 18, y: 7, w: 6, h: 7 } },
          writeAvailability { gridPos: { x: 0, y: 14, w: 6, h: 7 } },
          writeRequests { gridPos: { x: 6, y: 14, w: 6, h: 7 } },
          writeErrors { gridPos: { x: 12, y: 14, w: 6, h: 7 } },
          writeDuration { gridPos: { x: 18, y: 14, w: 6, h: 7 } },
          upCount { gridPos: { x: 0, y: 21, w: 4, h: 7 } },
          rpcRate { gridPos: { x: 4, y: 21, w: 10, h: 7 } },
          requestDuration { gridPos: { x: 14, y: 21, w: 10, h: 7 } },
          workQueueAddRate { gridPos: { x: 0, y: 28, w: 12, h: 7 } },
          workQueueDepth { gridPos: { x: 12, y: 28, w: 12, h: 7 } },
          workQueueLatency { gridPos: { x: 0, y: 35, w: 24, h: 7 } },
          memory { gridPos: { x: 0, y: 42, w: 8, h: 7 } },
          cpu { gridPos: { x: 8, y: 42, w: 8, h: 7 } },
          goroutines { gridPos: { x: 16, y: 42, w: 8, h: 7 } },
        ]
      ),
  },
}
