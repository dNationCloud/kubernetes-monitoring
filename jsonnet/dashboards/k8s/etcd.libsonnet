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

/* K8s etcd dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+::
    local etcdDashboard(dashboardUid, dashboardName, healthTemplate) = {
      local sel = $._config.grafanaDashboards.selectors,
      local promTarget(expr, legendFormat=null) = prometheus.withExpr(expr) + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {}),

      local health =
        statPanel.new('Health')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource') + statPanel.standardOptions.withUnit('percent')
        + statPanel.options.reduceOptions.withCalcs(['mean'])
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds(healthTemplate.panel.thresholds))
        + statPanel.queryOptions.withTargets([promTarget(healthTemplate.panel.expr)]),

      local timeSeriesBase(title, unit=null, fillOpacity=0, staircase=false, desc=null) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + (if desc != null then timeSeriesPanel.panelOptions.withDescription(desc) else {})
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(fillOpacity)
        + (if staircase then timeSeriesPanel.fieldConfig.defaults.custom.withLineInterpolation('stepAfter') else {})
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + timeSeriesPanel.options.tooltip.withMode('multi') + timeSeriesPanel.options.tooltip.withSort('desc'),

      local grpcRate = timeSeriesBase('GRPC Rate', 'reqps') + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2) + timeSeriesPanel.queryOptions.withTargets([
        promTarget('sum(rate(grpc_server_started_total{cluster="$cluster", %(etcd)s, instance=~"$instance", grpc_type="unary"}[5m]))' % sel, 'GRPC_Rate'),
        promTarget('sum(rate(grpc_server_handled_total{cluster="$cluster", %(etcd)s, instance=~"$instance", grpc_type="unary", grpc_code!="OK"}[5m]))' % sel, 'GRPC Failed Rate'),
      ]),

      local activeStreams = timeSeriesBase('Active Streams') + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2) + timeSeriesPanel.queryOptions.withTargets([
        promTarget('sum(grpc_server_started_total{cluster="$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Watch", grpc_type="bidi_stream"}) - sum(grpc_server_handled_total{cluster="$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Watch", grpc_type="bidi_stream"})' % sel, 'Watch Streams'),
        promTarget('sum(grpc_server_started_total{cluster="$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Lease", grpc_type="bidi_stream"}) - sum(grpc_server_handled_total{cluster="$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Lease", grpc_type="bidi_stream"})' % sel, 'Lease Streams'),
      ]),

      local dbSize = timeSeriesBase('DB Size', 'bytes') + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2) + timeSeriesPanel.queryOptions.withTargets([promTarget('etcd_mvcc_db_total_size_in_bytes{cluster="$cluster", %(etcd)s, instance=~"$instance"}' % sel, '{{instance}} DB Size')]),

      local diskSyncDuration = timeSeriesBase('Disk Sync Duration', 's', staircase=true) + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2) + timeSeriesPanel.queryOptions.withTargets([
        promTarget('histogram_quantile(0.99, sum(rate(etcd_disk_wal_fsync_duration_seconds_bucket{cluster="$cluster", %(etcd)s, instance=~"$instance"}[5m])) by (instance, le))' % sel, '{{instance}} WAL fsync'),
        promTarget('histogram_quantile(0.99, sum(rate(etcd_disk_backend_commit_duration_seconds_bucket{cluster="$cluster", %(etcd)s, instance=~"$instance"}[5m])) by (instance, le))' % sel, '{{instance}} DB fsync'),
      ]),

      local memory = timeSeriesBase('Memory', 'bytes') + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2) + timeSeriesPanel.queryOptions.withTargets([promTarget('process_resident_memory_bytes{cluster="$cluster", %(etcd)s, instance=~"$instance"}' % sel, '{{instance}} Resident Memory')]),
      local clientTrafficIn = timeSeriesBase('Client Traffic In', 'Bps', fillOpacity=50) + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(etcd_network_client_grpc_sent_bytes_total{cluster="$cluster", %(etcd)s, instance=~"$instance"}[5m])' % sel, '{{instance}} Client Traffic In')]),
      local clientTrafficOut = timeSeriesBase('Client Traffic Out', 'Bps', fillOpacity=50) + timeSeriesPanel.queryOptions.withTargets([promTarget('rate(etcd_network_client_grpc_sent_bytes_total{cluster="$cluster", %(etcd)s, instance=~"$instance"}[5m])' % sel, '{{instance}} Client Traffic Out')]),
      local totalLeaderElectionsPerDay = timeSeriesBase('Total Leader Elections PerDay') + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2) + timeSeriesPanel.queryOptions.withTargets([promTarget('changes(etcd_server_leader_changes_seen_total{cluster="$cluster", %(etcd)s, instance=~"$instance"}[1d])' % sel, 'Total Leader Elections Per Day')]),

      local raftproposal = timeSeriesBase('Raft Proposal') + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2) + timeSeriesPanel.queryOptions.withTargets([
        promTarget('sum(rate(etcd_server_proposals_failed_total{cluster="$cluster", %(etcd)s, instance=~"$instance"}[5m]))' % sel, 'Proposal Failure Rate'),
        promTarget('sum(etcd_server_proposals_pending{cluster="$cluster", %(etcd)s, instance=~"$instance"})' % sel, 'etcd_server_proposals_pending'),
        promTarget('sum(rate(etcd_server_proposals_committed_total{cluster="$cluster", %(etcd)s, instance=~"$instance"}[5m]))' % sel, 'Proposal Commit Rate'),
        promTarget('sum(rate(etcd_server_proposals_applied_total{cluster="$cluster", %(etcd)s, instance=~"$instance"}[5m]))' % sel, 'Proposal Apply Rate'),
      ]),

      dashboard:
        dashboard.new(dashboardName)
        + dashboard.withUid($._config.grafanaDashboards.ids.etcd)
        + dashboard.withTags($._config.grafanaDashboards.tags.k8sSystem)
        + dashboard.withEditable($._config.grafanaDashboards.editable)
        + dashboard.withRefresh($._config.grafanaDashboards.refresh)
        + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
        + $._config.grafanaDashboards.tooltip
        + dashboard.withTimezone('browser')
        + dashboard.withVariables([
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.clusterTemplate('label_values(etcd_server_has_leader, cluster)'),
          $.grafanaTemplates.instanceTemplate('label_values(etcd_server_has_leader{cluster="$cluster", %(etcd)s}, instance)' % sel),
        ])
        + dashboard.withPanels([
          health { gridPos: { h: 7, w: 6, x: 0, y: 0 } },
          grpcRate { gridPos: { h: 7, w: 10, x: 6, y: 0 } },
          activeStreams { gridPos: { h: 7, w: 8, x: 16, y: 0 } },
          dbSize { gridPos: { h: 7, w: 8, x: 0, y: 7 } },
          diskSyncDuration { gridPos: { h: 7, w: 8, x: 8, y: 7 } },
          memory { gridPos: { h: 7, w: 8, x: 16, y: 7 } },
          clientTrafficIn { gridPos: { h: 7, w: 6, x: 0, y: 14 } },
          clientTrafficOut { gridPos: { h: 7, w: 6, x: 6, y: 14 } },
          totalLeaderElectionsPerDay { gridPos: { h: 7, w: 12, x: 12, y: 14 } },
          raftproposal { gridPos: { h: 7, w: 12, x: 0, y: 21 } },
        ]),
    };
    $.createControlPlaneDashboard(
      jsonName='etcd',
      dashboardFunction=etcdDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.etcd,
      dashboardName='Etcd',
      templateGroup=$._config.templates.L1.k8s,
      templateName='etcdHealth',
    ),
}
