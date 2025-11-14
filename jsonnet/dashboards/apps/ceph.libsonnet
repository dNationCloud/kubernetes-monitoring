local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;
local gaugePanel = grafana.gaugePanel;

{
  grafanaDashboards+:: {
    ceph: (

      local clusterHealth =
        statPanel.new(
          title='Cluster Health',
          datasource='$datasource',
          unit='none',
          colorMode='value',
          graphMode='none',
        )

        .addThresholds([
          { color: '#299c46', value: null },
          { color: '#f4d598', value: 1 },
          { color: '#d44a3a', value: 2 },
        ])

        .addMapping({
          type: 'value',
          options: {
            '0': { text: 'HEALTHY' },
            '1': { text: 'WARNING' },
            '2': { text: 'ERROR' },
          },
        })

        .addTarget(
          prometheus.target('ceph_health_status{cluster="$cluster"}', legendFormat='Health')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local writeThroughput =
        statPanel.new(
          title='Write Throughput',
          datasource='$datasource',
          unit='Bps',
          decimals='1',
          graphMode='none',
        )

        .addTarget(
          prometheus.target('sum(irate(ceph_osd_op_w_in_bytes{cluster="$cluster"}[5m]))', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local readThroughput =
        statPanel.new(
          title='Read Throughput',
          datasource='$datasource',
          unit='Bps',
          decimals=1,
          graphMode='none',
        )

        .addTarget(
          prometheus.target('sum(irate(ceph_osd_op_r_out_bytes{cluster="$cluster"}[5m]))', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local clusterCapacity =
        statPanel.new(
          title='Cluster Capacity',
          datasource='$datasource',
          unit='decbytes',
          decimals=2,
          graphMode='none',
        )

        .addTarget(
          prometheus.target('ceph_cluster_total_bytes{cluster="$cluster"}', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local availableCapacity =
        gaugePanel.new(
          title='Available Capacity',
          datasource='$datasource',
          unit='percentunit',
          min=0,
          max=1,
        )

        .addThresholds([
          { color: 'rgba(245, 54, 54, 0.9)', value: null },
          { color: 'rgba(237, 129, 40, 0.89)', value: 0.1 },
          { color: 'rgba(50, 172, 45, 0.97)', value: 0.3 },
        ])

        .addTarget(
          prometheus.target('(ceph_cluster_total_bytes{cluster="$cluster"} - ceph_cluster_total_used_bytes{cluster="$cluster"}) / ceph_cluster_total_bytes{cluster="$cluster"}', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local writeIOPS =
        statPanel.new(
          title='Write IOPS',
          datasource='$datasource',
          unit='ops',
          decimals=0,
          graphMode='none',
        )

        .addTarget(
          prometheus.target('sum(irate(ceph_osd_op_w{cluster="$cluster"}[5m]))', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local readIOPS =
        statPanel.new(
          title='Read IOPS',
          datasource='$datasource',
          unit='ops',
          decimals=0,
          graphMode='none',
        )

        .addTarget(
          prometheus.target('sum(irate(ceph_osd_op_r{cluster="$cluster"}[5m]))', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local numObjects =
        statPanel.new(
          title='Number of Objects',
          datasource='$datasource',
          unit='short',
          decimals=2,
          graphMode='none',
        )

        .addTarget(
          prometheus.target('sum(ceph_pool_objects{cluster="$cluster"})', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local bytesWritten =
        statPanel.new(
          title='Bytes Written',
          datasource='$datasource',
          unit='decbytes',
          decimals=1,
          graphMode='none',
        )

        .addTarget(
          prometheus.target('ceph_cluster_total_used_bytes{cluster="$cluster"}', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['delta'],
              fields: '',
            },
          },
        };

      local bytesRead =
        statPanel.new(
          title='Bytes Read',
          datasource='$datasource',
          unit='decbytes',
          decimals=1,
          graphMode='none',
        )

        .addTarget(
          prometheus.target(expr='sum(ceph_osd_op_r_out_bytes{cluster="$cluster"})', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['delta'],
              fields: '',
            },
          },
        };

      local difference =
        statPanel.new(
          title='Difference',
          datasource='$datasource',
          unit='short',
          decimals=2,
          graphMode='none',
        )

        .addTarget(
          prometheus.target('sum(ceph_pool_objects)', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['diff'],
              fields: '',
            },
          },
        };

      local monSessionNum =
        statPanel.new(
          title='Mon Session Num',
          datasource='$datasource',
          unit='short',
          decimals=0,
          graphMode='none',
          colorMode='background',

        )

        .addTarget(
          prometheus.target('sum(ceph_mon_num_sessions{cluster="$cluster"})', legendFormat='')
        )

        .addThresholds([
          { color: 'rgba(245, 54, 54, 0.9)', value: 128 },
          { color: 'rgba(50, 172, 45, 0.97)', value: null },
        ])

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local monitorsInQuorum =
        statPanel.new(
          title='Monitors in Quorum',
          datasource='$datasource',
          unit='none',
          decimals=0,
          graphMode='none',
          colorMode='background',
        )

        .addTarget(
          prometheus.target('count(ceph_mon_quorum_status{cluster="$cluster"}) or vector(0)', legendFormat='')
        )

        .addThresholds([
          { color: 'rgba(245, 54, 54, 0.9)', value: null },
          { color: 'rgba(237, 129, 40, 0.89)', value: 2 },
          { color: 'rgba(50, 172, 45, 0.97)', value: 3 },
        ])

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local usedCapacity =
        statPanel.new(
          title='Used Capacity',
          datasource='$datasource',
          unit='decbytes',
          decimals=2,
          graphMode='none',
        )

        .addTarget(
          prometheus.target('ceph_cluster_total_used_bytes{cluster="$cluster"}', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local osdOut =
        statPanel.new(
          title='OSDs OUT',
          datasource='$datasource',
          unit='none',
          decimals=0,
          graphMode='none',
        )

        .addThresholds([
          { color: '#9ac48a', value: null },
          { color: 'rgba(237, 40, 40, 0.89)', value: 1 },
          { color: 'rgba(245, 54, 54, 0.9)', value: 1 },
        ])

        .addMapping(
          {
            id: 0,
            type: 'special',
            options: {
              match: null,
              result: { text: 'N/A' },
            },
          }
        )

        .addTarget(
          prometheus.target('count(ceph_osd_up{cluster="$cluster"}) - count(ceph_osd_in{cluster="$cluster"})', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local osdDown =
        statPanel.new(
          title='OSDs DOWN',
          datasource='$datasource',
          unit='none',
          decimals=0,
          graphMode='none',
        )

        .addThresholds([
          { color: '#9ac48a', value: null },
          { color: 'rgba(237, 40, 40, 0.89)', value: 1 },
          { color: 'rgba(245, 54, 54, 0.9)', value: 1 },
        ])

        .addMapping(
          {
            id: 0,
            type: 'special',
            options: {
              match: null,
              result: { text: 'N/A' },
            },
          }
        )

        .addTarget(
          prometheus.target('count(ceph_osd_up{cluster="$cluster"} == 0.0) OR vector(0)', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local osdUP =
        statPanel.new(
          title='OSDs UP',
          datasource='$datasource',
          unit='none',
          decimals=0,
          graphMode='none',
        )

        .addThresholds([
          { color: '#9ac48a', value: null },
          { color: 'rgba(245, 54, 54, 0.9)', value: 80 },
        ])

        .addMapping(
          {
            id: 0,
            type: 'special',
            options: {
              match: null,
              result: { text: 'N/A' },
            },
          }
        )

        .addTarget(
          prometheus.target('sum(ceph_osd_up{cluster="$cluster"})', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local osdIN =
        statPanel.new(
          title='OSDs IN',
          datasource='$datasource',
          unit='none',
          decimals=0,
          graphMode='none',
        )

        .addThresholds([
          { color: '#9ac48a', value: null },
          { color: 'rgba(245, 54, 54, 0.9)', value: 80 },
        ])

        .addMapping(
          {
            id: 0,
            type: 'special',
            options: {
              match: null,
              result: { text: 'N/A' },
            },
          }
        )

        .addTarget(
          prometheus.target('sum(ceph_osd_in{cluster="$cluster"})', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local avgPGs =
        statPanel.new(
          title='Avg PGs',
          datasource='$datasource',
          unit='none',
          decimals=1,
          graphMode='none',
        )

        .addThresholds([
          {
            color: 'rgba(50, 172, 45, 0.97)',
            value: null,
          },
          {
            color: 'rgba(237, 129, 40, 0.89)',
            value: 250,
          },
          {
            color: 'rgba(245, 54, 54, 0.9)',
            value: 300,
          },
        ])

        .addMapping(
          {
            id: 0,
            type: 'special',
            options: {
              match: null,
              result: { text: 'N/A' },
            },
          }
        )

        .addTarget(
          prometheus.target('sum(ceph_osd_numpg{cluster="$cluster"})', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local avgApplyLatency =
        statPanel.new(
          title='Avg Apply Latency',
          datasource='$datasource',
          unit='ms',
          decimals=2,
          graphMode='none',
        )

        .addThresholds([
          {
            color: 'rgba(50, 172, 45, 0.97)',
            value: null,
          },
          {
            color: 'rgba(237, 129, 40, 0.89)',
            value: 10,
          },
          {
            color: 'rgba(245, 54, 54, 0.9)',
            value: 50,
          },
        ])

        .addMapping(
          {
            id: 0,
            type: 'special',
            options: {
              match: null,
              result: { text: 'N/A' },
            },
          }
        )

        .addTarget(
          prometheus.target('avg(ceph_osd_apply_latency_ms{cluster="$cluster"})', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local avgCommitLatency =
        statPanel.new(
          title='Avg Commit Latency',
          datasource='$datasource',
          unit='ms',
          decimals=2,
          graphMode='none',
        )

        .addThresholds([
          {
            color: 'rgba(50, 172, 45, 0.97)',
            value: null,
          },
          {
            color: 'rgba(237, 129, 40, 0.89)',
            value: 10,
          },
          {
            color: 'rgba(245, 54, 54, 0.9)',
            value: 50,
          },
        ])

        .addMapping(
          {
            id: 0,
            type: 'special',
            options: {
              match: null,
              result: { text: 'N/A' },
            },
          }
        )

        .addTarget(
          prometheus.target('avg(ceph_osd_commit_latency_ms{cluster="$cluster"})', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local avgOPWriteLatency =
        statPanel.new(
          title='Avg OP Write Latency',
          datasource='$datasource',
          unit='ms',
          decimals=4,
          graphMode='none',
        )

        .addThresholds([
          {
            color: '#299c46',
            value: null,
          },
          {
            color: 'rgba(237, 129, 40, 0.89)',
            value: 1,
          },
          {
            color: '#d44a3a',
            value: 2,
          },
        ])

        .addMapping(
          {
            id: 0,
            type: 'special',
            options: {
              match: null,
              result: { text: 'N/A' },
            },
          }
        )

        .addTarget(
          prometheus.target('clamp_min(avg(rate(ceph_osd_op_w_latency_sum{cluster="$cluster"}[5m]) / clamp_min(rate(ceph_osd_op_w_latency_count{cluster="$cluster"}[5m]), 1)), 0) or vector(0)', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local avgOPReadLatency =
        statPanel.new(
          title='Avg OP Read Latency',
          datasource='$datasource',
          unit='ms',
          decimals=4,
          graphMode='none',
        )

        .addThresholds([
          {
            color: '#299c46',
            value: null,
          },
          {
            color: 'rgba(237, 129, 40, 0.89)',
            value: 1,
          },
          {
            color: '#d44a3a',
            value: 2,
          },
        ])

        .addMapping(
          {
            id: 0,
            type: 'special',
            options: {
              match: null,
              result: { text: 'N/A' },
            },
          }
        )

        .addTarget(
          prometheus.target('clamp_min(avg(rate(ceph_osd_op_r_latency_sum{cluster="$cluster"}[5m]) / clamp_min(rate(ceph_osd_op_r_latency_count{cluster="$cluster"}[5m]), 1)), 0) or vector(0)', legendFormat='')
        )

        + {
          options+: {
            reduceOptions: {
              values: false,
              calcs: ['lastNotNull'],
              fields: '',
            },
          },
        };

      local capacityPanel =
        graphPanel.new(
          title='Capacity',
          datasource='$datasource',
          stack=true,
          fill=5,
          lines=true,
          linewidth=1,
          points=false,
          nullPointMode='null',
        )

        .addTarget(
          prometheus.target(
            'ceph_cluster_total_bytes{cluster="$cluster"} - ceph_cluster_total_used_bytes{cluster="$cluster"}',
            legendFormat='Available'
          )
        )
        .addTarget(
          prometheus.target(
            'ceph_cluster_total_used_bytes{cluster="$cluster"}',
            legendFormat='Used'
          )
        )
        .addTarget(
          prometheus.target(
            'ceph_cluster_total_bytes{cluster="$cluster"}',
            legendFormat='Total Capacity'
          )
        )

        + {
          fieldConfig+: {
            defaults+: {
              unit: 'bytes',
              decimals: 2,
            },
          },
          aliasColors+: {
            Available: '#EAB839',
            Used: '#BF1B00',
            'Total Capacity': '#447EBC',
          },
          seriesOverrides: [
            { alias: 'Total Capacity', fill: 0, stack: false, linewidth: 3 },
          ],

          options+: {
            tooltip: { mode: 'multi', sort: 'desc' },
            legend: {
              showLegend: true,
              displayMode: 'table',
              placement: 'bottom',
              calcs: ['mean', 'lastNotNull', 'max', 'min'],
              showValues: true,
              hideEmpty: false,
              hideZero: false,
            },
          },
        };

      local iopsPanel =
        graphPanel.new(
          title='IOPS',
          datasource='$datasource',
          stack=true,
          fill=5,
          lines=true,
          linewidth=1,
          points=false,
          nullPointMode='null',
        )

        .addTarget(
          prometheus.target(
            'sum(irate(ceph_osd_op_w{cluster="$cluster"}[5m]))',
            legendFormat='Write'
          )
        )

        .addTarget(
          prometheus.target(
            'sum(irate(ceph_osd_op_r{cluster="$cluster"}[5m]))',
            legendFormat='Read'
          )
        )

        + {
          fieldConfig+: {
            defaults+: {
              unit: 'iops',
              decimals: 0,
              min: 0,
            },
          },

          aliasColors+: {
            Write: '#E24D42',
            Read: '#1F78C1',
          },

          seriesOverrides: [
            { alias: 'Write', fill: 6, stack: true, linewidth: 1 },
            { alias: 'Read', fill: 6, stack: true, linewidth: 1 },
          ],

          yaxes: [
            { format: 'Bps', label: null, logBase: 1, max: null, min: 0, show: true },
            { format: 'short', label: null, logBase: 1, max: null, min: null, show: true },
          ],

          options+: {
            tooltip: { mode: 'multi', sort: 'desc' },
            legend: {
              showLegend: true,
              displayMode: 'table',
              placement: 'bottom',
              calcs: ['mean', 'lastNotNull', 'max', 'min'],
              showValues: true,
              hideEmpty: false,
              hideZero: false,
            },
          },
        };

      local clusterThroughputPanel =
        graphPanel.new(
          title='Cluster Throughput',
          datasource='$datasource',
          stack=true,
          fill=5,
          lines=true,
          linewidth=1,
          points=false,
          nullPointMode='null',
        )
        .addTarget(
          prometheus.target(
            'sum(irate(ceph_osd_op_w_in_bytes{cluster="$cluster"}[5m]))',
            legendFormat='Write'
          )
        )

        .addTarget(
          prometheus.target(
            'sum(irate(ceph_osd_op_r_out_bytes{cluster="$cluster"}[5m]))',
            legendFormat='Read'
          )
        )

        + {
          fieldConfig+: {
            defaults+: {
              unit: 'decbytes',
              decimals: 1,
              barAlignment: 0,
            },
          },

          aliasColors+: {
            Write: '#E24D42',
            Read: '#1F78C1',
          },

          seriesOverrides: [
            { alias: 'Write', fill: 6, stack: true, linewidth: 1 },
            { alias: 'Read', fill: 6, stack: true, linewidth: 1 },
          ],

          yaxes: [
            { format: 'Bps', label: null, logBase: 1, max: null, min: 0, show: true },
            { format: 'short', label: null, logBase: 1, max: null, min: null, show: true },
          ],


          options+: {
            tooltip: { mode: 'multi', sort: 'desc' },
            legend: {
              showLegend: true,
              displayMode: 'table',
              placement: 'bottom',
              calcs: ['mean', 'lastNotNull', 'max', 'min'],
              showValues: true,
              hideEmpty: false,
              hideZero: false,
            },
          },
        };

      local poolUsedBytesPanel =
        graphPanel.new(
          title='Pool Used Bytes',
          datasource='$datasource',
          lines=true,
          linewidth=1,
          points=false,
          nullPointMode='null',
          stack=false,
          fill=1,
        )

        .addTarget(
          prometheus.target(
            '(ceph_pool_bytes_used{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})',
            legendFormat='{{name}}'
          )
        )

        + {
          fieldConfig+: {
            defaults+: {
              unit: 'bytes',
              decimals: 2,
              min: 0,
            },
          },

          options+: {
            tooltip: { mode: 'multi', sort: 'none' },
            legend: {
              showLegend: true,
              displayMode: 'list',
              placement: 'bottom',
              calcs: [],
            },
          },

          yaxes: [
            { format: 'bytes', label: null, logBase: 1, max: null, min: 0, show: true },
            { format: 'short', label: null, logBase: 1, max: null, min: null, show: true },
          ],
        };

      local poolRawBytesPanel =
        graphPanel.new(
          title='Pool RAW Bytes',
          datasource='$datasource',
          lines=true,
          linewidth=1,
          points=false,
          nullPointMode='null',
          stack=false,
          fill=1,
        )

        .addTarget(
          prometheus.target(
            '(ceph_pool_avail_raw{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})',
            legendFormat='{{name}} Avail'
          )
        )

        .addTarget(
          prometheus.target(
            '(ceph_pool_stored_raw{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})',
            legendFormat='{{name}} Stored'
          )
        )

        + {
          fieldConfig+: {
            defaults+: {
              unit: 'bytes',
              decimals: 2,
              min: 0,
            },
          },

          options+: {
            tooltip: { mode: 'multi', sort: 'none' },
            legend: {
              showLegend: true,
              displayMode: 'table',
              placement: 'right',
              calcs: [],
            },
          },

          yaxes: [
            { format: 'bytes', label: null, logBase: 1, max: null, min: 0, show: true },
            { format: 'short', label: null, logBase: 1, max: null, min: null, show: true },
          ],
        };

      local objectsPerPoolPanel =
        graphPanel.new(
          title='Objects Per Pool',
          datasource='$datasource',
          lines=true,
          linewidth=1,
          points=false,
          nullPointMode='null',
          stack=false,
          fill=1,
        )

        .addTarget(
          prometheus.target(
            '(ceph_pool_objects{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})',
            legendFormat='{{name}}'
          )
        )

        + {
          fieldConfig+: {
            defaults+: {
              unit: 'short',
              decimals: 0,
              min: 0,
            },
          },

          options+: {
            tooltip: { mode: 'multi', sort: 'none' },
            legend: {
              showLegend: true,
              displayMode: 'list',
              placement: 'right',
              calcs: [],
            },
          },

          yaxes: [
            { format: 'short', label: null, logBase: 1, max: null, min: 0, show: true },
            { format: 'short', label: null, logBase: 1, max: null, min: null, show: true },
          ],
        };

      local poolQuotaBytesPanel =
        graphPanel.new(
          title='Pool Quota Bytes',
          datasource='$datasource',
          lines=true,
          linewidth=1,
          points=false,
          nullPointMode='null',
          stack=false,
          fill=1,
        )

        .addTarget(
          prometheus.target(
            '(ceph_pool_quota_bytes{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})',
            legendFormat='{{name}}'
          )
        )

        + {
          fieldConfig+: {
            defaults+: {
              unit: 'bytes',
              decimals: 2,
              min: 0,
            },
          },

          options+: {
            tooltip: { mode: 'multi', sort: 'none' },
            legend: {
              showLegend: true,
              displayMode: 'list',
              placement: 'bottom',
              calcs: [],
            },
          },

          yaxes: [
            { format: 'bytes', label: null, logBase: 1, max: null, min: 0, show: true },
            { format: 'short', label: null, logBase: 1, max: null, min: null, show: true },
          ],
        };

      local poolObjectsQuotaPanel =
        graphPanel.new(
          title='Pool Objects Quota',
          datasource='$datasource',
          lines=true,
          linewidth=1,
          points=false,
          nullPointMode='null',
          stack=false,
          fill=1,
        )

        .addTarget(
          prometheus.target(
            '(ceph_pool_quota_objects{cluster="$cluster"}) * on (pool_id) group_left(name) (ceph_pool_metadata{cluster="$cluster"})',
            legendFormat='{{name}}'
          )
        )

        + {
          fieldConfig+: {
            defaults+: {
              unit: 'short',
              decimals: 0,
              min: 0,
            },
          },

          options+: {
            tooltip: { mode: 'multi', sort: 'none' },
            legend: {
              showLegend: true,
              displayMode: 'list',
              placement: 'bottom',  // presne ako v JSONe
              calcs: [],
            },
          },

          yaxes: [
            { format: 'short', label: null, logBase: 1, max: null, min: 0, show: true },
            { format: 'short', label: null, logBase: 1, max: null, min: null, show: true },
          ],
        };

      local osdTypeCountPanel =
        graphPanel.new(
          title='OSD Type Count',
          datasource='$datasource',
          lines=true,
          linewidth=1,
          points=false,
          nullPointMode='null',
          stack=false,
          fill=1,
        )

        .addTarget(
          prometheus.target(
            'count(ceph_bluestore_kv_commit_lat_count{cluster="$cluster"})',
            legendFormat='BlueStore'
          )
        )

        + {
          fieldConfig+: {
            defaults+: {
              unit: 'short',
              decimals: 0,
              min: 0,
            },
          },

          options+: {
            tooltip: { mode: 'multi', sort: 'none' },
            legend: {
              showLegend: true,
              displayMode: 'list',
              placement: 'bottom',
              calcs: [],
            },
          },

          yaxes: [
            { format: 'short', label: null, logBase: 1, max: null, min: 0, show: true },
            { format: 'short', label: null, logBase: 1, max: null, min: null, show: true },
          ],
        };

      local panels = [
        row.new('CLUSTER STATE') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        clusterHealth { gridPos: { x: 0, y: 1, w: 3, h: 6 } },
        writeThroughput { gridPos: { x: 3, y: 1, w: 3, h: 3 } },
        readThroughput { gridPos: { x: 6, y: 1, w: 3, h: 3 } },
        clusterCapacity { gridPos: { x: 9, y: 1, w: 3, h: 3 } },
        availableCapacity { gridPos: { x: 12, y: 1, w: 3, h: 6 } },
        writeIOPS { gridPos: { x: 3, y: 4, w: 3, h: 3 } },
        readIOPS { gridPos: { x: 6, y: 4, w: 3, h: 3 } },
        usedCapacity { gridPos: { x: 9, y: 4, w: 3, h: 3 } },
        numObjects { gridPos: { x: 15, y: 1, w: 3, h: 3 } },
        bytesWritten { gridPos: { x: 18, y: 1, w: 3, h: 3 } },
        bytesRead { gridPos: { x: 21, y: 1, w: 3, h: 3 } },
        difference { gridPos: { x: 15, y: 4, w: 3, h: 3 } },
        monSessionNum { gridPos: { x: 18, y: 4, w: 3, h: 3 } },
        monitorsInQuorum { gridPos: { x: 21, y: 4, w: 3, h: 3 } },
        row.new('OSD STATE', collapse=true) { gridPos: { x: 0, y: 8, w: 24, h: 1 } },
        osdOut { gridPos: { x: 0, y: 9, w: 2.55, h: 3 } },
        osdDown { gridPos: { x: 2.55, y: 9, w: 2.55, h: 3 } },
        osdUP { gridPos: { x: 5.1, y: 9, w: 2.55, h: 3 } },
        osdIN { gridPos: { x: 7.65, y: 9, w: 2.55, h: 3 } },
        avgPGs { gridPos: { x: 10.2, y: 9, w: 2.55, h: 3 } },
        avgApplyLatency { gridPos: { x: 12.75, y: 9, w: 2.55, h: 3 } },
        avgCommitLatency { gridPos: { x: 15.3, y: 9, w: 2.55, h: 3 } },
        avgOPWriteLatency { gridPos: { x: 17.85, y: 9, w: 3.15, h: 3 } },
        avgOPReadLatency { gridPos: { x: 21, y: 9, w: 3, h: 3 } },
        row.new('CLUSTER STATS', collapse=true) { gridPos: { x: 0, y: 24, w: 24, h: 1 } },
        capacityPanel { gridPos: { x: 0, y: 25, w: 8, h: 8 } },
        iopsPanel { gridPos: { x: 8, y: 25, w: 8, h: 8 } },
        clusterThroughputPanel { gridPos: { x: 16, y: 25, w: 8, h: 8 } },
        poolUsedBytesPanel { gridPos: { x: 0, y: 33, w: 8, h: 8 } },
        poolRawBytesPanel { gridPos: { x: 8, y: 33, w: 8, h: 8 } },
        objectsPerPoolPanel { gridPos: { x: 16, y: 33, w: 8, h: 8 } },
        poolQuotaBytesPanel { gridPos: { x: 0, y: 41, w: 8, h: 8 } },
        poolObjectsQuotaPanel { gridPos: { x: 8, y: 41, w: 8, h: 8 } },
        osdTypeCountPanel { gridPos: { x: 16, y: 41, w: 8, h: 8 } },
      ];

      dashboard.new(
        'Ceph Cluster Overview',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.ceph,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
      ])
      .addPanels(panels)
    ),
  },
}
