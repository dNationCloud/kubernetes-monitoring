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

/* SSL exporter dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local statPanel = grafana.panel.stat;
local table = grafana.panel.table;
local fieldOverride = grafana.panel.table.fieldOverride;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    'ssl-exporter':
      local color = $._config.grafanaDashboards.color;
      local week = 8 * 24 * 60 * 60;

      local tableTarget(expr) =
        prometheus.withExpr(expr) + prometheus.withFormat('table') + prometheus.withInstant(true);

      local statBase(title, steps) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.options.withColorMode('value')
        + statPanel.options.withGraphMode('none')
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps(steps);

      local totalUniqueCerts =
        statBase('Total Unique Certificates', [])
        + statPanel.queryOptions.withTargets([
          tableTarget('count(max(ssl_cert_not_after{cluster="$cluster", job=~"$job"}) by (issuer_cn, serial_no))'),
        ]);

      local totalProbeTargets =
        statBase('Total Probe Targets', [])
        + statPanel.queryOptions.withTargets([
          tableTarget('count(ssl_probe_success{cluster="$cluster"})'),
        ]);

      local failedSSLCount =
        statBase('Expired/Failed Certificates', [{ color: 'green', value: 0 }, { color: 'red', value: 1 }])
        + statPanel.queryOptions.withTargets([
          tableTarget('\n            (count(up{job=~"$job", cluster="$cluster"}==0) OR on() vector(0))+\n            (count(ssl_probe_success{cluster="$cluster"}==0) OR on() vector(0))+\n            (count((ssl_cert_not_after{cluster="$cluster"}-time())<0) OR on() vector(0))+\n            (count((ssl_file_not_after{cluster="$cluster"}-time())<0) OR on() vector(0))+\n            (count((ssl_kubeconfig_cert_not_after{cluster="$cluster"}-time())<0) OR on()vector(0))+\n            (count((ssl_kubernetes_cert_not_after{cluster="$cluster"}-time())<0) OR on()vector(0))\n            '),
        ]);

      local nearingExpiryCount =
        statBase('Certificates Nearing Expiration', [{ color: 'green', value: 0 }, { color: 'orange', value: 1 }])
        + statPanel.queryOptions.withTargets([
          tableTarget('\n            (count(0<(ssl_cert_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0))+\n            (count(0<(ssl_file_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0))+\n            (count(0<(ssl_kubeconfig_cert_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0)) +\n            (count(0<(ssl_kubernetes_cert_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0))\n            '),
        ]);

      local hide(name) = fieldOverride.byName.new(name)
                         + fieldOverride.byName.withProperty('custom.hidden', true);

      local rename(name, display) = fieldOverride.byName.new(name)
                                    + fieldOverride.byName.withProperty('displayName', display);

      local failedSSLConnect =
        table.new('Failed SSL Connects')
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + table.standardOptions.withOverrides([
          hide('Time'),
          hide('__name__'),
          fieldOverride.byName.new('Value')
          + fieldOverride.byName.withProperty('displayName', 'SSL Failed')
          + fieldOverride.byName.withProperty('unit', 'short')
          + fieldOverride.byName.withProperty('decimals', 0)
          + fieldOverride.byName.withProperty('custom.cellOptions', { type: 'color-background' })
          + fieldOverride.byName.withProperty('thresholds', { mode: 'absolute', steps: [{ color: color.red, value: null }, { color: color.green, value: 1 }] })
          + fieldOverride.byName.withProperty('custom.width', 140),
        ])
        + table.queryOptions.withTargets([
          tableTarget('ssl_probe_success{cluster="$cluster"}==0'),
        ]);

      local commonHidden = ['Time', '__name__', 'pod', 'job', 'endpoint', 'namespace', 'prometheus', 'container', 'prometheus_replica', 'service'];

      local ttlOverride =
        fieldOverride.byName.new('Value')
        + fieldOverride.byName.withProperty('displayName', 'TTL')
        + fieldOverride.byName.withProperty('unit', 's')
        + fieldOverride.byName.withProperty('decimals', 0)
        + fieldOverride.byName.withProperty('custom.cellOptions', { type: 'color-background' })
        + fieldOverride.byName.withProperty('thresholds', { mode: 'absolute', steps: [{ color: color.red, value: null }, { color: color.orange, value: 0 }, { color: color.green, value: week }] })
        + fieldOverride.byName.withProperty('custom.width', 77);

      local tableBase(title, metric, columns) =
        table.new(title)
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + table.standardOptions.withOverrides(
          [hide(name) for name in commonHidden]
          + [rename('serial_no', 'Serial No ')]
          + [
            if std.objectHas(col, 'hidden') then hide(col.pattern) else rename(col.pattern, col.alias)
            for col in columns
          ]
          + [ttlOverride]
        )
        + table.queryOptions.withTransformations([{ id: 'sortBy', options: { fields: {}, sort: [{ field: 'TTL' }] } }])
        + table.queryOptions.withTargets([
          tableTarget(metric),
        ]);

      local externalCerts = tableBase(
        'External SSL Certificates',
        'ssl_cert_not_after{ job=~"$job", cluster="$cluster" } - time()',
        [
          { pattern: 'instance', alias: 'Instance' },
          { pattern: 'cn', alias: 'CN' },
          { pattern: 'issuer_cn', alias: 'Issuer CN' },
          { pattern: 'dnsnames', alias: 'DNS Names' },
        ]
      );

      local k8sKubeconfig = tableBase(
        'Kubeconfig Certificates',
        'ssl_kubeconfig_cert_not_after{ job=~"$job", cluster="$cluster" } - time()',
        [
          { pattern: 'dnsnames', hidden: true },
          { pattern: 'instance', hidden: true },
          { pattern: 'name', alias: 'Name' },
          { pattern: 'cn', alias: 'CN' },
          { pattern: 'issuer_cn', alias: 'Issuer CN' },
          { pattern: 'kubeconfig', alias: 'Kubeconfig' },
        ]
      );

      local k8sFiles = tableBase(
        'Internal Kubernetes Certificates',
        'ssl_file_cert_not_after{ job=~"$job", cluster="$cluster" }* on(pod) group_left(node) kube_pod_info{ cluster="$cluster"} - time()',
        [
          { pattern: 'dnsnames', hidden: true },
          { pattern: 'instance', hidden: true },
          { pattern: 'cn', alias: 'CN' },
          { pattern: 'node', alias: 'Node' },
          { pattern: 'issuer_cn', alias: 'Issuer CN' },
          { pattern: 'kubeconfig', alias: 'Kubeconfig' },
        ]
      );

      local k8sSecrets = tableBase(
        'Kubernetes Secret Certificates',
        'ssl_kubernetes_cert_not_after{ job=~"$job", cluster="$cluster" } - time()',
        [
          { pattern: 'cn', alias: 'CN' },
          { pattern: 'issuer_cn', alias: 'Issuer CN' },
          { pattern: 'dnsnames', alias: 'DNS Names' },
        ]
      );

      local panels = [
        row.new('Overview') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        totalUniqueCerts { gridPos: { x: 0, y: 1, w: 6, h: 6 } },
        totalProbeTargets { gridPos: { x: 6, y: 1, w: 6, h: 6 } },
        failedSSLCount { gridPos: { x: 12, y: 1, w: 6, h: 6 } },
        nearingExpiryCount { gridPos: { x: 18, y: 1, w: 6, h: 6 } },
        row.new('Failed SSL Connects') + { gridPos: { x: 0, y: 7, w: 6, h: 1 } },
        failedSSLConnect { gridPos: { x: 0, y: 8, w: 24, h: 6 } },
        row.new('External SSL Certificates') + { gridPos: { x: 0, y: 14, w: 40, h: 1 } },
        externalCerts { gridPos: { x: 0, y: 15, w: 48, h: 8 } },
        row.new('Kubeconfig Certificates') + { gridPos: { x: 0, y: 23, w: 40, h: 1 } },
        k8sKubeconfig { gridPos: { x: 0, y: 24, w: 40, h: 8 } },
        row.new('Internal Kubernetes Certificates') + { gridPos: { x: 0, y: 32, w: 40, h: 1 } },
        k8sFiles { gridPos: { x: 0, y: 33, w: 40, h: 8 } },
        row.new('Kubernetes Secret Certificates') + { gridPos: { x: 0, y: 41, w: 40, h: 1 } },
        k8sSecrets { gridPos: { x: 0, y: 42, w: 42, h: 8 } },
      ];

      dashboard.new('SSL Certificates')
      + dashboard.withUid($._config.grafanaDashboards.ids.sslExporter)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(ssl_probe_success{cluster="$cluster"}, job)'),
        $.grafanaTemplates.instanceTemplate('label_values({job=~"$job"}, instance)'),
      ])
      + dashboard.withPanels(panels),
  },
}
