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

/* K8s scheduler dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;

{
  grafanaDashboards+:: {
    scheduler:
      local health =
        statPanel.new(
          title='Health',
          datasource='$datasource',
          unit='percent',
        )
        .addThresholds($.grafanaThresholds($._config.templates.k8s.schedulerHealth.panel.thresholds))
        .addTarget(prometheus.target($._config.templates.k8s.schedulerHealth.panel.expr));

      local schedulingRate =
        graphPanel.new(
          title='Scheduling Rate',
          datasource='$datasource',
          format='ops',
          min=0,
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(scheduler_e2e_scheduling_duration_seconds_count{cluster=~"$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance)' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} e2e'),
            prometheus.target('sum(rate(scheduler_binding_duration_seconds_count{cluster=~"$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance)' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} binding'),
            prometheus.target('sum(rate(scheduler_scheduling_algorithm_duration_seconds_count{cluster=~"$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance)' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} scheduling algorithm'),
            prometheus.target('sum(rate(scheduler_volume_scheduling_duration_seconds_count{cluster=~"$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance)' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} volume'),
          ]
        );

      local schedulingLatency =
        graphPanel.new(
          title='Scheduling latency 99th Quantile',
          datasource='$datasource',
          min=0,
          format='s',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
        )
        .addTargets(
          [
            prometheus.target('histogram_quantile(0.99, sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket{cluster=~"$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance, le))' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} e2e'),
            prometheus.target('histogram_quantile(0.99, sum(rate(scheduler_binding_duration_seconds_bucket{cluster=~"$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance, le))' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} binding'),
            prometheus.target('histogram_quantile(0.99, sum(rate(scheduler_scheduling_algorithm_duration_seconds_bucket{cluster=~"$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance, le))' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} scheduling algorithm'),
            prometheus.target('histogram_quantile(0.99, sum(rate(scheduler_volume_scheduling_duration_seconds_bucket{cluster=~"$cluster", %(scheduler)s, instance=~"$instance"}[5m])) by (instance, le))' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} volume'),
          ]
        );

      local rpcRate =
        graphPanel.new(
          title='Kube API Request Rate',
          datasource='$datasource',
          format='reqps',
          min=0,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(scheduler)s, instance=~"$instance", code=~"2.."}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='2xx'),
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(scheduler)s, instance=~"$instance", code=~"3.."}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='3xx'),
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(scheduler)s, instance=~"$instance", code=~"4.."}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='4xx'),
            prometheus.target('sum(rate(rest_client_requests_total{cluster=~"$cluster", %(scheduler)s, instance=~"$instance", code=~"5.."}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='5xx'),
          ]
        );

      local postRequestLatency =
        graphPanel.new(
          title='Post Request Latency 99th Quantile',
          datasource='$datasource',
          format='s',
          min=0,
        )
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(rest_client_request_duration_seconds_bucket{cluster=~"$cluster", %(scheduler)s, instance=~"$instance", verb="POST"}[5m])) by (verb, url, le))' % $._config.grafanaDashboards.selectors, legendFormat='{{verb}} {{url}}'));

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
        .addTarget(prometheus.target('histogram_quantile(0.99, sum(rate(rest_client_request_duration_seconds_bucket{cluster=~"$cluster", %(scheduler)s, instance=~"$instance", verb="GET"}[5m])) by (verb, url, le))' % $._config.grafanaDashboards.selectors, legendFormat='{{verb}} {{url}}'));

      local memory =
        graphPanel.new(
          title='Memory',
          datasource='$datasource',
          format='bytes',
        )
        .addTarget(prometheus.target('process_resident_memory_bytes{cluster=~"$cluster", %(scheduler)s, instance=~"$instance"}' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}}'));

      local cpu =
        graphPanel.new(
          title='CPU Usage',
          datasource='$datasource',
          min=0,
        )
        .addTarget(prometheus.target('rate(process_cpu_seconds_total{cluster=~"$cluster", %(scheduler)s, instance=~"$instance"}[5m])' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}}'));

      local goroutines =
        graphPanel.new(
          title='Goroutines',
          datasource='$datasource',
        )
        .addTarget(prometheus.target('go_goroutines{cluster=~"$cluster", %(scheduler)s, instance=~"$instance"}' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}}'));

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
          query='label_values(scheduler_e2e_scheduling_duration_seconds_count, cluster)',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      local instanceTemplate =
        template.new(
          name='instance',
          label='Instance',
          datasource='$datasource',
          query='label_values(process_cpu_seconds_total{cluster=~"$cluster", %(scheduler)s}, instance)' % $._config.grafanaDashboards.selectors,
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          includeAll=true,
          multi=true,
        );

      dashboard.new(
        'Scheduler',
        time_from=$._config.grafanaDashboards.time_from,
        uid=$._config.grafanaDashboards.ids.scheduler,
        editable=$._config.grafanaDashboards.editable,
        tags=$._config.grafanaDashboards.tags.k8sSystem,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
      )
      .addTemplates([datasourceTemplate, clusterTemplate, instanceTemplate])
      .addPanels(
        [
          health { gridPos: { x: 0, y: 0, w: 4, h: 7 } },
          schedulingRate { gridPos: { x: 4, y: 0, w: 10, h: 7 }, tooltip+: { sort: 2 } },
          schedulingLatency { gridPos: { x: 14, y: 0, w: 10, h: 7 }, tooltip+: { sort: 2 } },
          rpcRate { gridPos: { x: 0, y: 7, w: 8, h: 7 }, tooltip+: { sort: 2 } },
          postRequestLatency { gridPos: { x: 8, y: 7, w: 16, h: 7 }, tooltip+: { sort: 2 } },
          getRequestLatency { gridPos: { x: 0, y: 14, w: 24, h: 7 }, tooltip+: { sort: 2 } },
          memory { gridPos: { x: 0, y: 21, w: 8, h: 7 }, tooltip+: { sort: 2 } },
          cpu { gridPos: { x: 8, y: 21, w: 8, h: 7 }, tooltip+: { sort: 2 } },
          goroutines { gridPos: { x: 16, y: 21, w: 8, h: 7 }, tooltip+: { sort: 2 } },
        ]
      ),
  },
}
