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

/* Lokid Distributed dashboard*/
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;
{
  grafanaDashboards+:: {
    'loki-distributed':

      /*Function definitions*/
      local msgs_graph(title, target) =
        graphPanel.new(
          title=title,
          datasource='$datasource',
          format='bytes',
          nullPointMode='null as zero',
          legend_current=true,
          linewidth=2,
        )
        .addTarget(
          prometheus.target(
            expr='histogram_quantile(0.95, sum(rate( %s {cluster="$cluster", job=~"$job"}[1m])) by (le,route))' % target,
            legendFormat='{{route}}'
          )
        );

      local ingester_graph(title, target, legendFormat, format='short') =
        graphPanel.new(
          title=title,
          datasource='$datasource',
          format=format,
          nullPointMode='null as zero',
          legend_current=true,
          legend_values=true,
          fill=0,
          linewidth=1,
          legend_sort='current'
        )
        .addTarget(
          prometheus.target(
            expr='histogram_quantile(0.95, sum(rate( %s {cluster="$cluster", job=~"$job"}[1m])) by (le))' % target,
            legendFormat=legendFormat
          )
        );

      local querier_graph(title, target, format='short') =
        graphPanel.new(
          title=title,
          datasource='$datasource',
          format=format,
          nullPointMode='null as zero',
          legend_current=true,
          legend_values=true,
          fill=0,
          linewidth=2,
          legend_sort='current'
        )
        .addTarget(prometheus.target('%s{cluster="$cluster", job=~"$job"}' % target));

      /*Overview*/
      local version =
        statPanel.new(
          title='Loki Version',
          datasource='$datasource',
          fields='/^version$/',
          reducerFunction='last',
          graphMode='none',
          colorMode='background',
        )
        .addTarget(
          prometheus.target(
            format='table',
            expr='loki_build_info{cluster="$cluster", job=~"$job"}'
          )
        );
      local msgs =
        statPanel.new(
          title='Log Messages Total',
          datasource='$datasource',
          graphMode='none',
          reducerFunction='last',
          unit='short',
        )
        .addTarget(
          prometheus.target('sum(log_messages_total{cluster="$cluster", job=~"$job"})')
        );

      local errors =
        statPanel.new(
          title='Errors',
          datasource='$datasource',
          graphMode='none',
          reducerFunction='last',
          colorMode='background',
        )
        .addTarget(prometheus.target('sum(log_messages_total{cluster="$cluster", job=~"$job",level="error"})'))
        .addThreshold({ value: 0, color: 'green' })
        .addThreshold({ value: 1, color: 'orange' });

      local panic =
        statPanel.new(
          title='Panic',
          datasource='$datasource',
          graphMode='none',
          reducerFunction='last',
          colorMode='background',
        )
        .addTarget(prometheus.target(format='table', instant=false, expr='loki_panic_total{cluster="$cluster", job=~"$job"}'))
        .addThreshold({ value: 0, color: 'green' })
        .addThreshold({ value: 1, color: 'red' });

      /*Messages Input*/
      local msgs_input =
        graphPanel.new(
          title='Messages Input',
          datasource='$datasource',
          format='short',
          nullPointMode='null as zero',
          linewidth=1,
          fill=5,
          legend_values=true,
          x_axis_mode='time',
          legend_sort='current',
          legend_current=true,
        )
        .addTarget(
          prometheus.target(
            expr='sum(irate(log_messages_total{cluster="$cluster", job=~"$job"}[1m])) by (level)',
            legendFormat='{{operation}}'
          )
        );

      /*API Requests*/
      local api_requests =
        graphPanel.new(
          title='API Request Duration',
          datasource='$datasource',
          format='s',
          nullPointMode='null as zero',
          legend_current=true,
          fill=0,
          linewidth=2,
        )
        .addTarget(
          prometheus.target(
            expr='histogram_quantile(0.95, sum(rate(loki_request_duration_seconds_bucket{cluster="$cluster", job=~"$job"}[5m])) by (le,route))',
            legendFormat='{{route}}'
          )
        );

      local msgs_req_graph =
        msgs_graph(
          title='Request Size',
          target='loki_request_message_bytes_bucket',
        );
      local msgs_resp_graph =
        msgs_graph(
          title='Response Size',
          target='loki_response_message_bytes_bucket',
        );

      /*Ingester*/
      local ingester_blocks =
        ingester_graph(
          title='Blocks / Chunk',
          target='loki_ingester_blocks_per_chunk_bucket',
          legendFormat='blocks',
        );

      local ingester_chunk_size =
        ingester_graph(
          title='Chunk Size',
          target='loki_ingester_chunk_size_bytes_bucket',
          legendFormat='chunk size',
          format='decbytes',
        );

      local ingester_chunk_age =
        ingester_graph(
          title='Chunk Age',
          target='loki_ingester_chunk_age_seconds_bucket',
          legendFormat='ages',
          format='s',
        );

      local ingester_chunk_cmpratio =
        ingester_graph(
          title='Chunk Compression Ratios',
          target='loki_ingester_chunk_compression_ratio_bucket',
          legendFormat='ratio',
          format='percent',
        );

      local ingester_chunk_enctime =
        ingester_graph(
          title='Chunk Encode Time',
          target='loki_ingester_chunk_encode_time_seconds_bucket',
          legendFormat='time',
          format='s',
        );

      local ingester_lines =
        ingester_graph(
          title='Lines / Chunk',
          target='loki_ingester_chunk_entries_bucket',
          legendFormat='lines',
          format='short',
        );

      /*Cache*/
      local cache_size =
        graphPanel.new(
          title='Cache Value Size bytes',
          datasource='$datasource',
          format='decbytes',
          nullPointMode='null as zero',
          fill=0,
          linewidth=2,
        )
        .addTarget(
          prometheus.target(
            expr='histogram_quantile(0.95, sum(rate(loki_cache_value_size_bytes_bucket{cluster="$cluster", job=~"$job"}[5m])) by (le,name,method))',
            legendFormat='{{name}} / {{method}}'
          )
        );

      local cache_fetched_keys =
        graphPanel.new(
          title='Fetched Keys',
          datasource='$datasource',
          format='short',
          fill=1,
          linewidth=1,
        )
        .addTarget(prometheus.target(expr='loki_cache_fetched_keys{cluster="$cluster", job=~"$job"}', legendFormat='{{container}}/{{name}}'));

      local cache_hits_keys =
        graphPanel.new(
          title='Hits Keys',
          datasource='$datasource',
          format='short',
          fill=1,
          linewidth=1,
        )
        .addTarget(prometheus.target(expr='rate(loki_cache_hits{cluster="$cluster", job=~"$job"}[5m])', legendFormat='{{container}}/{{name}}'));

      /*Querrier*/
      local querier_cache_corruptions =
        querier_graph(
          title='Cache Corruptions',
          target='loki_querier_index_cache_corruptions_total'
        );

      local querier_cache_errors =
        querier_graph(
          title='Cache Encode Errors',
          target='loki_querier_index_cache_encode_errors_total'
        );

      local querier_cache_gets =
        querier_graph(
          title='Cache Gets',
          target='loki_querier_index_cache_gets_total'
        );

      local querier_cache_hits =
        querier_graph(
          title='Cache Hits',
          target='loki_querier_index_cache_hits_total'
        );

      local querier_cache_puts =
        querier_graph(
          title='Cache Puts',
          target='loki_querier_index_cache_puts_total'
        );

      /*Panels*/
      local panel_msgs(sy) =
        row.new('Messages Input', collapse=true) { gridPos: { x: 0, y: sy, w: 24, h: 1 } }
        .addPanel(msgs_input { tooltip+: { sort: 2 } }, { x: 0, y: sy + 1, w: 24, h: 7 });

      local panel_api(sy) =
        row.new('API Requests', collapse=true) { gridPos: { x: 0, y: sy, w: 24, h: 1 } }
        .addPanel(api_requests { tooltip+: { sort: 2 } }, { x: 0, y: sy + 1, w: 24, h: 7 })
        .addPanel(msgs_req_graph { tooltip+: { sort: 2 } }, { x: 0, y: sy + 8, w: 12, h: 7 })
        .addPanel(msgs_resp_graph { tooltip+: { sort: 2 } }, { x: 12, y: sy + 8, w: 12, h: 7 });

      local panel_ingester(sy) =
        row.new('Ingester', collapse=true) { gridPos: { x: 0, y: sy, w: 24, h: 1 } }
        .addPanel(ingester_blocks { tooltip+: { sort: 2 } }, { x: 0, y: sy + 1, w: 8, h: 7 })
        .addPanel(ingester_chunk_size { tooltip+: { sort: 2 } }, { x: 8, y: sy + 1, w: 8, h: 7 })
        .addPanel(ingester_chunk_age { tooltip+: { sort: 2 } }, { x: 16, y: sy + 1, w: 8, h: 7 })
        .addPanel(ingester_chunk_cmpratio { tooltip+: { sort: 2 } }, { x: 0, y: sy + 8, w: 8, h: 7 })
        .addPanel(ingester_chunk_enctime { tooltip+: { sort: 2 } }, { x: 8, y: sy + 8, w: 8, h: 7 })
        .addPanel(ingester_lines { tooltip+: { sort: 2 } }, { x: 16, y: sy + 8, w: 8, h: 7 });

      local panel_cache(sy) =
        row.new('Cache', collapse=true) { gridPos: { x: 0, y: sy, w: 24, h: 1 } }
        .addPanel(cache_size { tooltip+: { sort: 2 } }, { x: 0, y: sy + 1, w: 12, h: 7 })
        .addPanel(cache_fetched_keys { tooltip+: { sort: 2 } }, { x: 12, y: sy + 1, w: 12, h: 7 })
        .addPanel(cache_hits_keys { tooltip+: { sort: 2 } }, { x: 0, y: sy + 8, w: 12, h: 7 });

      local panel_querrier(sy) =
        row.new('Querier', collapse=true) { gridPos: { x: 0, y: sy, w: 24, h: 1 } }
        .addPanel(querier_cache_hits { tooltip+: { sort: 2 } }, { x: 0, y: sy + 1, w: 8, h: 7 })
        .addPanel(querier_cache_puts { tooltip+: { sort: 2 } }, { x: 8, y: sy + 1, w: 8, h: 7 })
        .addPanel(querier_cache_gets { tooltip+: { sort: 2 } }, { x: 16, y: sy + 1, w: 8, h: 7 })
        .addPanel(querier_cache_corruptions { tooltip+: { sort: 2 } }, { x: 0, y: sy + 8, w: 12, h: 7 })
        .addPanel(querier_cache_errors { tooltip+: { sort: 2 } }, { x: 12, y: sy + 8, w: 12, h: 7 });

      local panels = [
        row.new('Overview') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        version { gridPos: { x: 0, y: 1, w: 4, h: 5 } },
        msgs { gridPos: { x: 4, y: 1, w: 4, h: 5 } },
        errors { gridPos: { x: 8, y: 1, w: 4, h: 5 } },
        panic { gridPos: { x: 12, y: 1, w: 4, h: 5 } },
        panel_msgs(6),
        panel_api(14),
        panel_cache(29),
        panel_querrier(44),
        panel_ingester(59),
      ];

      dashboard.new(
        'Loki Distributed',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.lokiDistributed,
      )

      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(loki_build_info{cluster="$cluster"}, job)'),
      ])
      .addPanels(panels),
  },

}
