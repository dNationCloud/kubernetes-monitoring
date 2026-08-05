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

/* K8s rabbitmq overview dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local table = grafana.panel.table;
local fieldOverride = grafana.panel.table.fieldOverride;
local barGaugePanel = grafana.panel.barGauge;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    'rabbitmq-overview':
      local color = $._config.grafanaDashboards.color;
      local nodePalette = [color.green, color.darkyellow, color.darkblue, color.purple, color.orange, color.lightgreen, color.lightyellow, color.lightblue, color.lightpurple, color.lightorange];

      local rabbitRedOverride = [fieldOverride.byRegexp.new('/rabbit/')
                                 + fieldOverride.byRegexp.withProperty('color', { fixedColor: color.red, mode: 'fixed' })];

      local nodeColors = [
        fieldOverride.byRegexp.new('/^rabbit@[a-zA-Z\\.\\-]*?%d(\\b|\\.)/' % i)
        + fieldOverride.byRegexp.withProperty('color', { fixedColor: nodePalette[i], mode: 'fixed' })
        for i in std.range(0, 9)
      ];

      local statBase(title, expr, steps, gp, unit='none', decimals=null, mappings=[{ type: 'special', options: { match: 'null', result: { text: 'N/A' } } }]) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.panelOptions.withDescription('')
        + statPanel.options.withColorMode('background') + statPanel.options.withGraphMode('area')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.standardOptions.withUnit(unit)
        + (if decimals != null then statPanel.standardOptions.withDecimals(decimals) else {})
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps(steps)
        + statPanel.standardOptions.withMappings(mappings)
        + statPanel.queryOptions.withTargets([prometheus.withExpr(expr) + prometheus.withInstant(true)])
        + { gridPos: gp };

      local timeSeriesBase(title, desc, expr, gp, fillOpacity=100, stacking='normal', steps=[{ color: color.green, value: null }, { color: color.red, value: 80 }], tStyle='off', overrides=nodeColors, unit='short', decimals=0, spanNulls=false, legendFormat='{{rabbitmq_node}}', targets=null, hasMin=true) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.panelOptions.withDescription(desc)
        + timeSeriesPanel.standardOptions.color.withMode('palette-classic')
        + timeSeriesPanel.standardOptions.withUnit(unit)
        + (if hasMin then timeSeriesPanel.standardOptions.withMin(0) else {})
        + (if decimals != null then timeSeriesPanel.standardOptions.withDecimals(decimals) else {})
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(fillOpacity)
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(spanNulls)
        + timeSeriesPanel.fieldConfig.defaults.custom.stacking.withMode(stacking) + timeSeriesPanel.fieldConfig.defaults.custom.stacking.withGroup('A')
        + timeSeriesPanel.fieldConfig.defaults.custom.thresholdsStyle.withMode(tStyle)
        + timeSeriesPanel.standardOptions.thresholds.withMode('absolute') + timeSeriesPanel.standardOptions.thresholds.withSteps(steps)
        + timeSeriesPanel.options.legend.withShowLegend(false) + timeSeriesPanel.options.legend.withDisplayMode('list') + timeSeriesPanel.options.legend.withPlacement('bottom') + timeSeriesPanel.options.legend.withCalcs(['lastNotNull', 'max', 'min'])
        + timeSeriesPanel.options.tooltip.withMode('multi')
        + (if std.length(overrides) > 0 then timeSeriesPanel.standardOptions.withOverrides(overrides) else {})
        + timeSeriesPanel.queryOptions.withTargets(if targets != null then targets else [prometheus.withExpr(expr) + prometheus.withLegendFormat(legendFormat)])
        + { gridPos: gp };

      local topStats = [
        statBase('Ready messages',
                 'sum(rabbitmq_queue_messages_ready * on(instance, job) group_left(rabbitmq_cluster) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace", rabbitmq_endpoint="$endpoint"})',
                 [{ color: color.green, value: null }, { color: color.blue, value: 10000 }, { color: color.red, value: 100000 }],
                 { h: 3, w: 6, x: 0, y: 0 }),
        statBase('Outgoing messages / s',
                 'sum(irate(rabbitmq_global_messages_delivered_total[$__rate_interval]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})',
                 [{ color: color.red, value: null }, { color: color.blue, value: -1 }, { color: color.green, value: 50 }],
                 { h: 3, w: 6, x: 6, y: 0 },
                 'short',
                 0,
                 [{ type: 'special', options: { match: 'null', result: { index: 0, text: '0' } } }]),
        statBase('Publishers',
                 'sum(rabbitmq_global_publishers * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})',
                 [{ color: color.red, value: null }, { color: color.blue, value: 0 }, { color: color.green, value: 10 }],
                 { h: 3, w: 4, x: 12, y: 0 }),
        statBase('Connections',
                 'sum(rabbitmq_connections * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})',
                 [{ color: color.red, value: null }, { color: color.blue, value: 0 }, { color: color.green, value: 10 }],
                 { h: 3, w: 4, x: 16, y: 0 }),
        statBase('Queues',
                 'sum(rabbitmq_queues * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})',
                 [{ color: color.red, value: null }, { color: color.blue, value: 0 }, { color: color.green, value: 10 }],
                 { h: 3, w: 4, x: 20, y: 0 }),
        statBase('Unacknowledged messages',
                 'sum(rabbitmq_queue_messages_unacked * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})',
                 [{ color: color.green, value: null }, { color: color.blue, value: 100 }, { color: color.red, value: 500 }],
                 { h: 3, w: 6, x: 0, y: 3 },
                 'short'),
        statBase('Incoming messages / s',
                 'sum(irate(rabbitmq_global_messages_received_total[$__rate_interval]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})',
                 [{ color: color.red, value: null }, { color: color.blue, value: -1 }, { color: color.green, value: 50 }],
                 { h: 3, w: 6, x: 6, y: 3 },
                 'short',
                 0,
                 [{ type: 'special', options: { match: 'null', result: { index: 0, text: '0' } } }]),
        statBase('Consumers',
                 'sum(rabbitmq_global_consumers * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})',
                 [{ color: color.red, value: null }, { color: color.blue, value: 0 }, { color: color.green, value: 10 }],
                 { h: 3, w: 4, x: 12, y: 3 }),
        statBase('Channels',
                 'sum(rabbitmq_channels * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})',
                 [{ color: color.red, value: null }, { color: color.blue, value: 0 }, { color: color.green, value: 10 }],
                 { h: 3, w: 4, x: 16, y: 3 }),
        statBase('Nodes',
                 'count(rabbitmq_identity_info{namespace="$namespace",rabbitmq_cluster="$rabbitmq_cluster",rabbitmq_endpoint="$endpoint"})',
                 [{ color: color.blue, value: null }, { color: color.green, value: 3 }, { color: color.red, value: 8 }],
                 { h: 3, w: 4, x: 20, y: 3 },
                 'none',
                 null,
                 [{ type: 'special', options: { match: 'null', result: { index: 0, text: '0' } } }]),
      ];

      local nodesTable =
        table.new('')
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + table.standardOptions.color.withMode('thresholds')
        + table.standardOptions.thresholds.withMode('percentage') + table.standardOptions.thresholds.withSteps([{ color: color.green, value: null }, { color: color.red, value: 1 }])
        + table.standardOptions.withOverrides([
          fieldOverride.byName.new('erlang_version')
          + fieldOverride.byName.withProperty('displayName', 'Erlang/OTP')
          + fieldOverride.byName.withProperty('unit', 'none')
          + { properties+: [{ id: 'custom.align' }] }
          + fieldOverride.byName.withProperty('thresholds', { mode: 'absolute', steps: [{ color: color.green, value: null }, { color: color.orange }] }),
          fieldOverride.byName.new('rabbitmq_version')
          + fieldOverride.byName.withProperty('displayName', 'Version')
          + fieldOverride.byName.withProperty('thresholds', { mode: 'absolute', steps: [{ color: color.red, value: null }, { color: color.orange }] }),
          fieldOverride.byName.new('instance')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('rabbitmq_node')
          + fieldOverride.byName.withProperty('displayName', 'Node name')
          + fieldOverride.byName.withProperty('thresholds', { mode: 'absolute', steps: [{ color: color.red, value: null }, { color: color.orange }] }),
          fieldOverride.byName.new('Time')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('Value')
          + fieldOverride.byName.withProperty('custom.hidden', false)
          + fieldOverride.byName.withProperty('unit', 'clocks')
          + fieldOverride.byName.withProperty('displayName', 'Uptime')
          + fieldOverride.byName.withProperty('custom.width', 104),
          fieldOverride.byName.new('job')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('rabbitmq_cluster')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('prometheus_client_version')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('prometheus_plugin_version')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('namespace')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('endpoint')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('container')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('service')
          + fieldOverride.byName.withProperty('custom.hidden', true),
          fieldOverride.byName.new('pod')
          + fieldOverride.byName.withProperty('custom.hidden', true),
        ])
        + table.queryOptions.withTransformations([{ id: 'organize', options: { excludeByName: {}, includeByName: {}, indexByName: { Time: 3, Value: 10, erlang_version: 2, instance: 4, job: 5, namespace: 6, prometheus_client_version: 7, prometheus_plugin_version: 8, rabbitmq_cluster: 9, rabbitmq_node: 0, rabbitmq_version: 1 }, renameByName: {} } }])
        + table.queryOptions.withTargets([prometheus.withExpr('rabbitmq_erlang_uptime_seconds *on(instance,job) group_left(rabbitmq_version, erlang_version) rabbitmq_build_info * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{namespace="$namespace", rabbitmq_cluster="$rabbitmq_cluster", rabbitmq_endpoint="$endpoint"}') + prometheus.withFormat('table') + prometheus.withInstant(true)])
        + { gridPos: { h: 5, w: 24, x: 0, y: 7 } };

      local memAvail = timeSeriesBase('Memory available before publishers blocked',
                                      'If the value is zero or less, the memory alarm will be triggered and all publishing connections across all cluster nodes will be blocked.',
                                      '(rabbitmq_resident_memory_limit_bytes * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) -\n(rabbitmq_process_resident_memory_bytes * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})',
                                      { h: 8, w: 12, x: 0, y: 12 },
                                      fillOpacity=0,
                                      stacking='none',
                                      steps=[{ color: color.red, value: null }, { color: color.orange, value: 0 }, { color: 'transparent', value: 536870912 }],
                                      tStyle='line+area',
                                      unit='bytes',
                                      decimals=null,
                                      spanNulls=true,
                                      hasMin=false);

      local diskAvail = timeSeriesBase('Disk space available before publishers blocked',
                                       'This metric is reported for the partition where the RabbitMQ data directory is stored.',
                                       'rabbitmq_disk_space_available_bytes * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}',
                                       { h: 8, w: 12, x: 12, y: 12 },
                                       fillOpacity=0,
                                       stacking='none',
                                       steps=[{ color: color.red, value: null }, { color: color.orange, value: 1073741824 }, { color: 'transparent', value: 5368709120 }],
                                       tStyle='line+area',
                                       unit='bytes',
                                       decimals=null,
                                       spanNulls=true,
                                       hasMin=false);

      local qReady = timeSeriesBase('Messages ready to be delivered to consumers',
                                    'Total number of ready messages ready to be delivered to consumers.',
                                    'sum(rabbitmq_queue_messages_ready * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                    { h: 5, w: 12, x: 0, y: 21 });

      local qUnacked = timeSeriesBase('Messages pending consumer acknowledgement',
                                      'The total number of messages that are either in-flight to consumers, currently being processed by consumers or simply waiting for the consumer acknowledgements to be processed by the queue.',
                                      'sum(rabbitmq_queue_messages_unacked * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                      { h: 5, w: 12, x: 12, y: 21 });

      local published = timeSeriesBase('Messages published / s',
                                       'The incoming message rate before any routing rules are applied.',
                                       'sum(rate(rabbitmq_global_messages_received_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                       { h: 5, w: 9, x: 0, y: 27 });

      local avgSize =
        statPanel.new('Avg Size')
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.panelOptions.withDescription("Average message size. Doesn't account for stream protocol.")
        + statPanel.options.withColorMode('value') + statPanel.options.withGraphMode('area') + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.standardOptions.withUnit('decbytes') + statPanel.standardOptions.withDecimals(0) + statPanel.standardOptions.withNoValue('Requires RabbitMQ 4.1+')
        + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps([{ color: color.green, value: null }, { color: color.red, value: 80 }])
        + { interval: '30s' }
        + statPanel.queryOptions.withTargets([prometheus.withExpr('sum (increase(rabbitmq_message_size_bytes_sum[$__range]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) / sum (increase(rabbitmq_message_size_bytes_count[$__range]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})') + prometheus.withLegendFormat('{{protocol}}')])
        + { gridPos: { h: 5, w: 2, x: 9, y: 27 } };

      local sizeBucket(rangeName, upperBound, lowerBound) =
        local messagesUpTo(size) = 'sum(increase(rabbitmq_message_size_bytes_bucket{le="%s"}[$__range]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})' % size;

        local expr =
          if lowerBound == null then '%s / %s' % [messagesUpTo(upperBound), messagesUpTo('+Inf')]
          else '(%s - %s) / %s' % [messagesUpTo(upperBound), messagesUpTo(lowerBound), messagesUpTo('+Inf')];

        prometheus.withExpr(expr) + prometheus.withLegendFormat(rangeName) + prometheus.withInstant(true) + { refId: rangeName };

      local sizeDist =
        barGaugePanel.new('Message Size Distribution')
        + barGaugePanel.queryOptions.withDatasource('prometheus', '$datasource')
        + barGaugePanel.panelOptions.withDescription("Percent of incoming messages per size range. Doesn't account for stream protocol.")
        + barGaugePanel.standardOptions.withUnit('percentunit') + barGaugePanel.standardOptions.withDecimals(1) + barGaugePanel.standardOptions.withNoValue('Requires RabbitMQ 4.1+')
        + barGaugePanel.standardOptions.thresholds.withMode('absolute') + barGaugePanel.standardOptions.thresholds.withSteps([{ color: color.green, value: null }, { color: color.red, value: 80 }])
        + barGaugePanel.options.withDisplayMode('gradient') + barGaugePanel.options.withValueMode('color') + barGaugePanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + barGaugePanel.options.legend.withShowLegend(false)
        + barGaugePanel.standardOptions.withOverrides([
          fieldOverride.byQuery.new('0-100B')
          + fieldOverride.byQuery.withProperty('color', { fixedColor: color.green, mode: 'fixed' }),
          fieldOverride.byQuery.new('100B-1KB')
          + fieldOverride.byQuery.withProperty('color', { fixedColor: color.lightgreen, mode: 'fixed' }),
          fieldOverride.byQuery.new('1KB-10KB')
          + fieldOverride.byQuery.withProperty('color', { fixedColor: color.lightyellow, mode: 'fixed' }),
          fieldOverride.byQuery.new('10KB-100KB')
          + fieldOverride.byQuery.withProperty('color', { fixedColor: color.yellow, mode: 'fixed' }),
          fieldOverride.byQuery.new('100KB-1MB')
          + fieldOverride.byQuery.withProperty('color', { fixedColor: color.lightorange, mode: 'fixed' }),
          fieldOverride.byQuery.new('1MB-10MB')
          + fieldOverride.byQuery.withProperty('color', { fixedColor: color.orange, mode: 'fixed' }),
          fieldOverride.byQuery.new('10MB-50MB')
          + fieldOverride.byQuery.withProperty('color', { fixedColor: color.red, mode: 'fixed' }),
          fieldOverride.byQuery.new('50MB-100MB')
          + fieldOverride.byQuery.withProperty('color', { fixedColor: color.darkred, mode: 'fixed' }),
          fieldOverride.byQuery.new('100MB+')
          + fieldOverride.byQuery.withProperty('color', { fixedColor: color.darkerred, mode: 'fixed' }),
        ])
        + barGaugePanel.queryOptions.withTargets([
          sizeBucket('0-100B', '100', null),
          sizeBucket('100B-1KB', '1000', '100'),
          sizeBucket('1KB-10KB', '10000', '1000'),
          sizeBucket('10KB-100KB', '100000', '10000'),
          sizeBucket('100KB-1MB', '1000000', '100000'),
          sizeBucket('1MB-10MB', '10000000', '1000000'),
          sizeBucket('10MB-50MB', '50000000', '10000000'),
          sizeBucket('50MB-100MB', '100000000', '50000000'),
          sizeBucket('100MB+', '+Inf', '100000000'),
        ])
        + { gridPos: { h: 5, w: 13, x: 11, y: 27 } };

      local routed = timeSeriesBase('Messages routed to queues / s',
                                    'The rate of messages received from publishers and successfully routed to the master queue replicas.',
                                    'sum(rate(rabbitmq_global_messages_routed_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                    { h: 5, w: 12, x: 0, y: 32 });

      local confirmed = timeSeriesBase('Messages confirmed to publishers / s',
                                       'The rate of messages confirmed by the broker to publishers.',
                                       'sum(rate(rabbitmq_global_messages_confirmed_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                       { h: 5, w: 12, x: 12, y: 32 });

      local unroutable = timeSeriesBase('Unroutable messages dropped & returned / s',
                                        'The rate of messages that cannot be routed and are dropped.',
                                        '',
                                        { h: 5, w: 12, x: 0, y: 37 },
                                        steps=[{ color: 'transparent', value: null }, { color: color.red, value: 0 }],
                                        tStyle='line+area',
                                        overrides=rabbitRedOverride,
                                        decimals=null,
                                        targets=[
                                          prometheus.withExpr('sum(rate(rabbitmq_global_messages_unroutable_dropped_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)') + prometheus.withLegendFormat('dropped {{rabbitmq_node}}'),
                                          prometheus.withExpr('sum(rate(rabbitmq_global_messages_unroutable_returned_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)') + prometheus.withLegendFormat('returned to publishers {{rabbitmq_node}}'),
                                        ]);

      local unconfirmed = timeSeriesBase('Messages unconfirmed to publishers / s',
                                         'The rate of messages received from publishers that have publisher confirms enabled and the broker has not confirmed yet.',
                                         'sum(rate(rabbitmq_global_messages_received_confirm_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"} - \nrate(rabbitmq_global_messages_confirmed_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}\n) by(rabbitmq_node)',
                                         { h: 5, w: 12, x: 12, y: 37 },
                                         spanNulls=true);

      local delivered = timeSeriesBase('Messages delivered / s',
                                       'The rate of messages delivered to consumers. It includes messages that have been redelivered.',
                                       'sum(\n  (rate(rabbitmq_global_messages_delivered_consume_auto_ack_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) +\n  (rate(rabbitmq_global_messages_delivered_consume_manual_ack_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"})\n) by(rabbitmq_node)',
                                       { h: 5, w: 12, x: 0, y: 43 });

      local redelivered = timeSeriesBase('Messages redelivered / s',
                                         'The rate of messages that have been redelivered to consumers.',
                                         'sum(rate(rabbitmq_global_messages_redelivered_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                         { h: 5, w: 12, x: 12, y: 43 },
                                         steps=[{ color: 'transparent', value: null }, { color: color.orange, value: 20 }, { color: color.red, value: 100 }],
                                         tStyle='line+area',
                                         decimals=null);

      local manualAck = timeSeriesBase('Messages delivered with manual ack / s',
                                       'The rate of message deliveries to consumers that use manual acknowledgement mode.',
                                       'sum(rate(rabbitmq_global_messages_delivered_consume_manual_ack_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                       { h: 5, w: 12, x: 0, y: 48 });

      local autoAck = timeSeriesBase('Messages delivered auto ack / s',
                                     'The rate of message deliveries to consumers that use automatic acknowledgement mode.',
                                     'sum(rate(rabbitmq_global_messages_delivered_consume_auto_ack_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                     { h: 5, w: 12, x: 12, y: 48 });

      local acknowledged = timeSeriesBase('Messages acknowledged / s',
                                          'The rate of message acknowledgements coming from consumers that use manual acknowledgement mode.',
                                          'sum(rate(rabbitmq_global_messages_acknowledged_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                          { h: 5, w: 12, x: 0, y: 53 });

      local pollAuto = timeSeriesBase('Polling operations with auto ack / s',
                                      'The rate of messages delivered to polling consumers that use automatic acknowledgement mode.',
                                      'sum(rate(rabbitmq_global_messages_delivered_get_auto_ack_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                      { h: 5, w: 12, x: 12, y: 53 },
                                      steps=[{ color: 'transparent', value: null }, { color: color.red, value: 0 }],
                                      tStyle='line+area',
                                      overrides=rabbitRedOverride,
                                      decimals=null);

      local pollEmpty = timeSeriesBase('Polling operations that yield no result / s',
                                       'The rate of polling consumer operations that yield no result.',
                                       'sum(rate(rabbitmq_global_messages_get_empty_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                       { h: 5, w: 12, x: 0, y: 58 },
                                       steps=[{ color: 'transparent', value: null }, { color: color.red, value: 0 }],
                                       tStyle='line+area',
                                       overrides=rabbitRedOverride,
                                       decimals=null);

      local pollManual = timeSeriesBase('Polling operations with manual ack / s',
                                        'The rate of messages delivered to polling consumers that use manual acknowledgement mode.',
                                        'sum(rate(rabbitmq_global_messages_delivered_get_manual_ack_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                        { h: 5, w: 12, x: 12, y: 58 },
                                        steps=[{ color: 'transparent', value: null }, { color: color.red, value: 0 }],
                                        tStyle='line+area',
                                        overrides=rabbitRedOverride,
                                        decimals=null);

      local totalQueues = timeSeriesBase('Total queues',
                                         'Total number of queue masters per node.',
                                         'rabbitmq_queues * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}',
                                         { h: 5, w: 12, x: 0, y: 64 },
                                         decimals=null);

      local queuesDeclared = timeSeriesBase('Queues declared / s',
                                            'The rate of queue declarations performed by clients.',
                                            'sum(rate(rabbitmq_queues_declared_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                            { h: 5, w: 4, x: 12, y: 64 },
                                            steps=[{ color: 'transparent', value: null }, { color: color.orange, value: 2 }, { color: color.red, value: 10 }],
                                            tStyle='line+area',
                                            decimals=null);

      local queuesCreated = timeSeriesBase('Queues created / s',
                                           'The rate of new queues created (as opposed to redeclarations).',
                                           'sum(rate(rabbitmq_queues_created_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                           { h: 5, w: 4, x: 16, y: 64 },
                                           steps=[{ color: 'transparent', value: null }, { color: color.orange, value: 2 }, { color: color.red, value: 10 }],
                                           tStyle='line+area',
                                           decimals=null);

      local queuesDeleted = timeSeriesBase('Queues deleted / s',
                                           'The rate of queues deleted.',
                                           'sum(rate(rabbitmq_queues_deleted_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                           { h: 5, w: 4, x: 20, y: 64 },
                                           steps=[{ color: 'transparent', value: null }, { color: color.orange, value: 2 }, { color: color.red, value: 10 }],
                                           tStyle='line+area',
                                           decimals=null);

      local totalChannels = timeSeriesBase('Total channels',
                                           'Total number of channels on all currently opened connections.',
                                           'rabbitmq_channels * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}',
                                           { h: 5, w: 12, x: 0, y: 70 },
                                           decimals=null);

      local channelsOpened = timeSeriesBase('Channels opened / s',
                                            'The rate of new channels opened by applications across all connections.',
                                            'sum(rate(rabbitmq_channels_opened_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                            { h: 5, w: 6, x: 12, y: 70 },
                                            steps=[{ color: 'transparent', value: null }, { color: color.orange, value: 2 }, { color: color.red, value: 10 }],
                                            tStyle='line+area',
                                            decimals=null);

      local channelsClosed = timeSeriesBase('Channels closed / s',
                                            'The rate of channels closed by applications across all connections.',
                                            'sum(rate(rabbitmq_channels_closed_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                            { h: 5, w: 6, x: 18, y: 70 },
                                            steps=[{ color: 'transparent', value: null }, { color: color.orange, value: 2 }, { color: color.red, value: 10 }],
                                            tStyle='line+area',
                                            decimals=null);

      local totalConns = timeSeriesBase('Total connections',
                                        'Total number of client connections.',
                                        'rabbitmq_connections * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}',
                                        { h: 5, w: 12, x: 0, y: 76 },
                                        decimals=null);

      local connsOpened = timeSeriesBase('Connections opened / s',
                                         'The rate of new connections opened by clients.',
                                         'sum(rate(rabbitmq_connections_opened_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                         { h: 5, w: 6, x: 12, y: 76 },
                                         steps=[{ color: 'transparent', value: null }, { color: color.orange, value: 2 }, { color: color.red, value: 10 }],
                                         tStyle='line+area',
                                         decimals=null);

      local connsClosed = timeSeriesBase('Connections closed / s',
                                         'The rate of connections closed.',
                                         'sum(rate(rabbitmq_connections_closed_total[60s]) * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster="$rabbitmq_cluster", namespace="$namespace",rabbitmq_endpoint="$endpoint"}) by(rabbitmq_node)',
                                         { h: 5, w: 6, x: 18, y: 76 },
                                         steps=[{ color: 'transparent', value: null }, { color: color.orange, value: 2 }, { color: color.red, value: 10 }],
                                         tStyle='line+area',
                                         decimals=null);

      local titleRow(title, y) = row.new(title) + { gridPos: { h: 1, w: 24, x: 0, y: y } };

      dashboard.new('RabbitMQ-Overview')
      + dashboard.withUid($._config.grafanaDashboards.ids.rabbitmq)
      + dashboard.withDescription('A RabbitMQ Management Overview')
      + dashboard.withTags(['rabbitmq-prometheus', 'L1', 'app', 'k8s'])
      + dashboard.withEditable(true)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip + { gnetId: 10991 }
      + dashboard.withTimezone('browser')
      + dashboard.withLinks([{ icon: 'doc', tags: [], targetBlank: true, title: 'Monitoring with Prometheus & Grafana', tooltip: '', type: 'link', url: 'https://www.rabbitmq.com/prometheus.html' }])
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.namespaceTemplate('label_values(rabbitmq_identity_info, namespace)', includeAll=false, multi=false),
        $.grafanaTemplates.baseTemplate('rabbitmq_cluster', 'RabbitMQ Cluster', 'label_values(rabbitmq_identity_info{namespace="$namespace"},rabbitmq_cluster)', includeAll=false, multi=false),
        $.grafanaTemplates.baseTemplate('endpoint', 'Endpoint', 'label_values(rabbitmq_identity_info{namespace="$namespace", rabbitmq_cluster="$rabbitmq_cluster", rabbitmq_endpoint!="memory-breakdown"},rabbitmq_endpoint)', hide='variable', includeAll=false, multi=false),
      ])
      + dashboard.withPanels(
        topStats
        + [titleRow('NODES', 6), nodesTable, memAvail, diskAvail]
        + [titleRow('QUEUED MESSAGES', 20), qReady, qUnacked]
        + [titleRow('INCOMING MESSAGES', 26), published, avgSize, sizeDist, routed, confirmed, unroutable, unconfirmed]
        + [titleRow('OUTGOING MESSAGES', 42), delivered, redelivered, manualAck, autoAck, acknowledged, pollAuto, pollEmpty, pollManual]
        + [titleRow('QUEUES', 63), totalQueues, queuesDeclared, queuesCreated, queuesDeleted]
        + [titleRow('CHANNELS', 69), totalChannels, channelsOpened, channelsClosed]
        + [titleRow('CONNECTIONS', 75), totalConns, connsOpened, connsClosed]
      ),
  },
}
