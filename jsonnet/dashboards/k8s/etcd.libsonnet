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

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;

{
  grafanaDashboards+::
    local etcdDashboard(dashboardUid, dashboardName, healthTemplate) = {
      local health =
        statPanel.new(
          title='Health',
          datasource='$datasource',
          unit='percent',
        )
        .addThresholds($.grafanaThresholds(healthTemplate.panel.thresholds))
        .addTarget(prometheus.target(healthTemplate.panel.expr)),

      local grpcRate =
        graphPanel.new(
          title='GRPC Rate',
          datasource='$datasource',
          linewidth=2,
          format='reqps',
          fill=0,
          legend_show=false,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(grpc_server_started_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_type="unary"}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='GRPC_Rate'),
            prometheus.target('sum(rate(grpc_server_handled_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_type="unary", grpc_code!="OK"}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='GRPC Failed Rate'),
          ]
        ),

      local activeStreams =
        graphPanel.new(
          title='Active Streams',
          datasource='$datasource',
          linewidth=2,
          fill=0,
          legend_show=false,
        )
        .addTargets(
          [
            prometheus.target('sum(grpc_server_started_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Watch", grpc_type="bidi_stream"}) - sum(grpc_server_handled_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Watch", grpc_type="bidi_stream"})' % $._config.grafanaDashboards.selectors, legendFormat='Watch Streams'),
            prometheus.target('sum(grpc_server_started_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Lease", grpc_type="bidi_stream"}) - sum(grpc_server_handled_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Lease", grpc_type="bidi_stream"})' % $._config.grafanaDashboards.selectors, legendFormat='Lease Streams'),
          ]
        ),

      local dbSize =
        graphPanel.new(
          title='DB Size',
          datasource='$datasource',
          format='bytes',
          linewidth=2,
          fill=0,
          legend_show=false,
        )
        .addTarget(prometheus.target('etcd_mvcc_db_total_size_in_bytes{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} DB Size')),

      local diskSyncDuration =
        graphPanel.new(
          title='Disk Sync Duration',
          datasource='$datasource',
          format='s',
          linewidth=2,
          fill=0,
          legend_show=false,
          staircase=true,
        )
        .addTargets(
          [
            prometheus.target('histogram_quantile(0.99, sum(rate(etcd_disk_wal_fsync_duration_seconds_bucket{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m])) by (instance, le))' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} WAL fsync'),
            prometheus.target('histogram_quantile(0.99, sum(rate(etcd_disk_backend_commit_duration_seconds_bucket{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m])) by (instance, le))' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} DB fsync'),
          ]
        ),

      local memory =
        graphPanel.new(
          title='Memory',
          datasource='$datasource',
          format='bytes',
          linewidth=2,
          fill=0,
          legend_show=false,
        )
        .addTarget(prometheus.target('process_resident_memory_bytes{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} Resident Memory')),

      local clientTrafficIn =
        graphPanel.new(
          title='Client Traffic In',
          datasource='$datasource',
          format='Bps',
          fill=5,
          legend_show=false,
        )
        .addTarget(prometheus.target('rate(etcd_network_client_grpc_sent_bytes_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m])' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} Client Traffic In')),

      local clientTrafficOut =
        graphPanel.new(
          title='Client Traffic Out',
          datasource='$datasource',
          format='Bps',
          fill=5,
          legend_show=false,
        )
        .addTarget(prometheus.target('rate(etcd_network_client_grpc_sent_bytes_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m])' % $._config.grafanaDashboards.selectors, legendFormat='{{instance}} Client Traffic Out')),

      local totalLeaderElectionsPerDay =
        graphPanel.new(
          linewidth=2,
          title='Total Leader Elections PerDay',
          datasource='$datasource',
          fill=0,
          legend_show=false,
        )
        .addTarget(prometheus.target('changes(etcd_server_leader_changes_seen_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[1d])' % $._config.grafanaDashboards.selectors, legendFormat='Total Leader Elections Per Day')),

      local raftproposal =
        graphPanel.new(
          title='Raft Proposal',
          datasource='$datasource',
          linewidth=2,
          fill=0,
          legend_show=false,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(etcd_server_proposals_failed_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='Proposal Failure Rate'),
            prometheus.target('sum(etcd_server_proposals_pending{cluster=~"$cluster", %(etcd)s, instance=~"$instance"})' % $._config.grafanaDashboards.selectors, legendFormat='etcd_server_proposals_pending'),
            prometheus.target('sum(rate(etcd_server_proposals_committed_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='Proposal Commit Rate'),
            prometheus.target('sum(rate(etcd_server_proposals_applied_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m]))' % $._config.grafanaDashboards.selectors, legendFormat='Proposal Apply Rate'),
          ]
        ),

      dashboard:
        dashboard.new(
          dashboardName,
          uid=$._config.grafanaDashboards.ids.etcd,
          editable=$._config.grafanaDashboards.editable,
          tags=$._config.grafanaDashboards.tags.k8sSystem,
          graphTooltip=$._config.grafanaDashboards.tooltip,
          refresh=$._config.grafanaDashboards.refresh,
          time_from=$._config.grafanaDashboards.time_from,
        )
        .addTemplates([
          $.grafanaTemplates.datasourceTemplate(),
          $.grafanaTemplates.clusterTemplate('label_values(etcd_server_has_leader, cluster)'),
          $.grafanaTemplates.instanceTemplate('label_values(etcd_server_has_leader{cluster=~"$cluster", %(etcd)s}, instance)' % $._config.grafanaDashboards.selectors),
        ])
        .addPanels(
          [
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
          ]
        ),
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
