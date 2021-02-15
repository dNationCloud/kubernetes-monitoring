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

/* K8s controller manager dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;

{
  grafanaDashboards+::
    local controllerManagerDashboard(clusterUid, dashboardName, healthTemplate) = {
      local health =
        statPanel.new(
          title='Health',
          datasource='$datasource',
          unit='percent',
        )
        .addThresholds($.grafanaThresholds(healthTemplate.panel.thresholds))
        .addTarget(prometheus.target(healthTemplate.panel.expr)),

      local workQueueAddRate =
        graphPanel.new(
          title='Work Queue Add Rate',
          datasource='$datasource',
          format='ops',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('sum(rate(workqueue_adds_total{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance"}[5m])) by (instance, name)' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} {{name}}')),

      local workQueueDepth =
        graphPanel.new(
          title='Work Queue Depth',
          datasource='$datasource',
          min=0,
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('sum(rate(workqueue_depth{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance"}[5m])) by (instance, name)' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} {{name}}')),

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
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(workqueue_queue_duration_seconds_bucket{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance"}[5m])) by (instance, name, le))' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} {{name}}')),

      local grpcRate =
        graphPanel.new(
          title='Kube API Request Rate',
          datasource='$datasource',
          format='reqps',
        )
        .addTargets(
          [
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance", code=~"2.."}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='2xx'),
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance", code=~"3.."}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='3xx'),
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance", code=~"4.."}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='4xx'),
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance", code=~"5.."}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='5xx'),
          ]
        ),

      local postRequestLatency =
        graphPanel.new(
          title='Post Request Latency 99th Quantile',
          datasource='$datasource',
          format='s',
          min=0,
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(rest_client_request_duration_seconds_bucket{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance", verb="POST"}[5m])) by (verb, url, le))' % $._config.grafanaDashboards.selectors, legendFormat='{{verb}} {{url}}')),

      local getRequestLatency =
        graphPanel.new(
          title='Get Request Latency 99th Quantile',
          datasource='$datasource',
          format='s',
          min=0,
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(rest_client_request_duration_seconds_bucket{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance", verb="GET"}[5m])) by (verb, url, le))' % $._config.grafanaDashboards.selectors, legendFormat='{{verb}} {{url}}')),

      local memory =
        graphPanel.new(
          title='Memory',
          datasource='$datasource',
          format='bytes',
        )
        .addTarget(prometheus.target('process_resident_memory_bytes{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance"}' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}}')),

      local cpu =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          min=0,
        )
        .addTarget(prometheus.target('rate(process_cpu_seconds_total{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance"}[5m])' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}}')),

      local goroutines =
        graphPanel.new(
          title='Goroutines',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('go_goroutines{cluster=~"$cluster", %(controllerManager)s, instance=~"$instance"}' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}}')),

      dashboard:
        dashboard.new(
          dashboardName,
          time_from=$._config.grafanaDashboards.time_from,
          uid=$._config.grafanaDashboards.ids.controllerManager,
          editable=$._config.grafanaDashboards.editable,
          tags=$._config.grafanaDashboards.tags.k8sSystem,
          graphTooltip=$._config.grafanaDashboards.tooltip,
          refresh=$._config.grafanaDashboards.refresh,
        )
        .addTemplates([
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.clusterTemplate('label_values(workqueue_adds_total, cluster)'),
          $.grafanaTemplates.instanceTemplate('label_values(process_cpu_seconds_total{cluster=~"$cluster", %(controllerManager)s}, instance)' % $._config.grafanaDashboards.selectors),
        ])
        .addPanels(
          [
            health { gridPos: { x: 0, y: 0, w: 4, h: 7 } },
            workQueueAddRate { gridPos: { x: 4, y: 0, w: 20, h: 7 }, tooltip+: { sort: 2 } },
            workQueueDepth { gridPos: { x: 0, y: 14, w: 24, h: 7 }, tooltip+: { sort: 2 } },
            workQueueLatency { gridPos: { x: 0, y: 21, w: 24, h: 7 }, tooltip+: { sort: 2 } },
            grpcRate { gridPos: { x: 0, y: 28, w: 24, h: 7 }, tooltip+: { sort: 2 } },
            postRequestLatency { gridPos: { x: 0, y: 35, w: 12, h: 7 }, tooltip+: { sort: 2 } },
            getRequestLatency { gridPos: { x: 12, y: 35, w: 12, h: 7 }, tooltip+: { sort: 2 } },
            memory { gridPos: { x: 0, y: 42, w: 8, h: 7 }, tooltip+: { sort: 2 } },
            cpu { gridPos: { x: 8, y: 42, w: 8, h: 7 }, tooltip+: { sort: 2 } },
            goroutines { gridPos: { x: 16, y: 42, w: 8, h: 7 }, tooltip+: { sort: 2 } },
          ]
        ),
    };
    $.createControlPlaneDashboard(
      jsonName='controller-manager',
      dashboardFunction=controllerManagerDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.controllerManager,
      dashboardName='Controller Manager',
      templateGroup=$._config.templates.L1.k8s,
      templateName='controllerManagerHealth',
    ),
}
