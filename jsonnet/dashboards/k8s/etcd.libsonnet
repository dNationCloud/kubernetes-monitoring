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
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;

{
  grafanaDashboards+:: {
    'etcd':
      local upCount =
        statPanel.new(
          title='Up',
          datasource='$datasource',
        )
        .addThresholds($.grafanaThresholds($._config.thresholds.controlPlane))
        .addTarget(prometheus.target('sum(etcd_server_has_leader{cluster=~"$cluster", %(etcd)s})' % $._config.dashboardSelectors));

      local rpcRate =
        graphPanel.new(
          title='RPC Rate',
          datasource='$datasource',
          linewidth=2,
          format='reqps',
          fill=0,
          legend_show=false,
        )
        .addTargets(
          [
            prometheus.target('sum(rate(grpc_server_started_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_type="unary"}[5m]))' % $._config.dashboardSelectors, legendFormat='RPC_Rate'),
            prometheus.target('sum(rate(grpc_server_handled_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_type="unary", grpc_code!="OK"}[5m]))' % $._config.dashboardSelectors, legendFormat='RPC Failed Rate'),
          ]
        );

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
            prometheus.target('sum(grpc_server_started_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Watch", grpc_type="bidi_stream"}) - sum(grpc_server_handled_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Watch", grpc_type="bidi_stream"})' % $._config.dashboardSelectors, legendFormat='Watch Streams'),
            prometheus.target('sum(grpc_server_started_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Lease", grpc_type="bidi_stream"}) - sum(grpc_server_handled_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance", grpc_service="etcdserverpb.Lease", grpc_type="bidi_stream"})' % $._config.dashboardSelectors, legendFormat='Lease Streams'),
          ]
        );

      local dbSize =
        graphPanel.new(
          title='DB Size',
          datasource='$datasource',
          format='bytes',
          linewidth=2,
          fill=0,
          legend_show=false,
        )
        .addTarget(prometheus.target('etcd_mvcc_db_total_size_in_bytes{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}' % $._config.dashboardSelectors, legendFormat='{{instance}} DB Size'));

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
            prometheus.target('histogram_quantile(0.99, sum(rate(etcd_disk_wal_fsync_duration_seconds_bucket{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m])) by (instance, le))' % $._config.dashboardSelectors, legendFormat='{{instance}} WAL fsync'),
            prometheus.target('histogram_quantile(0.99, sum(rate(etcd_disk_backend_commit_duration_seconds_bucket{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m])) by (instance, le))' % $._config.dashboardSelectors, legendFormat='{{instance}} DB fsync'),
          ]
        );

      local memory =
        graphPanel.new(
          title='Memory',
          datasource='$datasource',
          format='bytes',
          linewidth=2,
          fill=0,
          legend_show=false,
        )
        .addTarget(prometheus.target('process_resident_memory_bytes{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}' % $._config.dashboardSelectors, legendFormat='{{instance}} Resident Memory'));

      local clientTrafficIn =
        graphPanel.new(
          title='Client Traffic In',
          datasource='$datasource',
          format='Bps',
          fill=5,
          legend_show=false,
        )
        .addTarget(prometheus.target('rate(etcd_network_client_grpc_sent_bytes_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m])' % $._config.dashboardSelectors, legendFormat='{{instance}} Client Traffic In'));

      local clientTrafficOut =
        graphPanel.new(
          title='Client Traffic Out',
          datasource='$datasource',
          format='Bps',
          fill=5,
          legend_show=false,
        )
        .addTarget(prometheus.target('rate(etcd_network_client_grpc_sent_bytes_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m])' % $._config.dashboardSelectors, legendFormat='{{instance}} Client Traffic Out'));

      local totalLeaderElectionsPerDay =
        graphPanel.new(
          linewidth=2,
          title='Total Leader Elections PerDay',
          datasource='$datasource',
          fill=0,
          legend_show=false,
        )
        .addTarget(prometheus.target('changes(etcd_server_leader_changes_seen_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[1d])' % $._config.dashboardSelectors, legendFormat='Total Leader Elections Per Day'));

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
            prometheus.target('sum(rate(etcd_server_proposals_failed_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m]))' % $._config.dashboardSelectors, legendFormat='Proposal Failure Rate'),
            prometheus.target('sum(etcd_server_proposals_pending{cluster=~"$cluster", %(etcd)s, instance=~"$instance"})' % $._config.dashboardSelectors, legendFormat='etcd_server_proposals_pending'),
            prometheus.target('sum(rate(etcd_server_proposals_committed_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m]))' % $._config.dashboardSelectors, legendFormat='Proposal Commit Rate'),
            prometheus.target('sum(rate(etcd_server_proposals_applied_total{cluster=~"$cluster", %(etcd)s, instance=~"$instance"}[5m]))' % $._config.dashboardSelectors, legendFormat='Proposal Apply Rate'),
          ]
        );

      local datasourceTemplate =
        template.datasource(
          query='prometheus',
          name='datasource',
          current=null,
          label='Datasource',
        );

      local clusterTemplate =
        template.new(
          name='cluster',
          label='Cluster',
          datasource='$datasource',
          query='label_values(etcd_server_has_leader, cluster)',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local instanceTemplate =
        template.new(
          name='instance',
          query='label_values(etcd_server_has_leader{cluster=~"$cluster", %(etcd)s}, instance)' % $._config.dashboardSelectors,
          label='Instance',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          includeAll=true,
          multi=true,
        );

      dashboard.new(
        'Etcd',
        uid=$._config.dashboardIDs.etcd,
        editable=$._config.dashboardCommon.editable,
        tags=$._config.dashboardCommon.tags.k8sSystem,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
      )
      .addTemplates([datasourceTemplate, instanceTemplate, clusterTemplate])
      .addPanels(
        [
          upCount { gridPos: { h: 7, w: 6, x: 0, y: 0 } },
          rpcRate { gridPos: { h: 7, w: 10, x: 6, y: 0 } },
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
  },
}
