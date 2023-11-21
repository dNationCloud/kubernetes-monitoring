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
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local row = grafana.row;
local table = grafana.tablePanel;
local statPanel = grafana.statPanel;

{
  grafanaDashboards+:: {

    'ssl-exporter':
      local totalUniqueCerts =
        statPanel.new(
          title='Total Unique Certificates',
          datasource='$datasource',
          graphMode='none',
        )
        .addTarget(
          prometheus.target(
            format='table',
            expr='count(max(ssl_cert_not_after{cluster="$cluster", job=~"$job"}) by (issuer_cn, serial_no))',
            instant=true,
          )
        );

      local totalProbeTargets =
        statPanel.new(
          title='Total Probe Targets',
          datasource='$datasource',
          graphMode='none',
        )
        .addTarget(
          prometheus.target(
            format='table',
            expr='count(ssl_probe_success{cluster="$cluster"})',
            instant=true,
          )
        );

      local failedSSLCount =
        statPanel.new(
          title='Expired/Failed Certificates',
          datasource='$datasource',
          graphMode='none',
        )
        .addTarget(
          prometheus.target(
            expr='\n            (count(up{job=~"$job", cluster="$cluster"}==0) OR on() vector(0))+\n            (count(ssl_probe_success{cluster="$cluster"}==0) OR on() vector(0))+\n            (count((ssl_cert_not_after{cluster="$cluster"}-time())<0) OR on() vector(0))+\n            (count((ssl_file_not_after{cluster="$cluster"}-time())<0) OR on() vector(0))+\n            (count((ssl_kubeconfig_cert_not_after{cluster="$cluster"}-time())<0) OR on()vector(0))+\n            (count((ssl_kubernetes_cert_not_after{cluster="$cluster"}-time())<0) OR on()vector(0))\n            ',
            format='table',
            instant=true,
          )
        )
        .addThreshold({ value: 0, color: 'green' })
        .addThreshold({ value: 1, color: 'red' });

      local nearingExpiryCount =
        statPanel.new(
          title='Certificates Nearing Expiration',
          datasource='$datasource',
          graphMode='none',
        ).addTarget(
          prometheus.target(
            expr='\n            (count(0<(ssl_cert_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0))+\n            (count(0<(ssl_file_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0))+\n            (count(0<(ssl_kubeconfig_cert_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0)) +\n            (count(0<(ssl_kubernetes_cert_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0))\n            ',
            format=table,
            instant=true,
          )
        )
        .addThreshold({ value: 0, color: 'green' })
        .addThreshold({ value: 1, color: 'orange' });

      local failedSSLConnect =
        table.new(
          title='Failed SSL Connects',
          datasource='$datasource',
          styles=[
            {
              alias: 'SSL Failed',
              align: 'auto',
              colorMode: 'row',
              colors: [
                'rgba(245,54,54,0.9)',
                'rgba(237,129,40,0.89)',
                'rgba(50,172,45,0.97)',
              ],
              dateFormat: 'YYYY-MM-DD HH:mm:ss',
              decimals: 0,
              mappingType: 1,
              pattern: 'Value',
              thresholds: ['1'],
              type: 'number',
              unit: 'short',
            },
            { pattern: 'Time', type: 'hidden' },
            { pattern: '__name__', type: 'hidden' },
          ]
        ).addTarget(
          prometheus.target(
            expr='ssl_probe_success{cluster="$cluster"}==0',
            format='table',
            intervalFactor=1,
            instant=true,
            legendFormat='',
          )
        );

      local sslExternalDesc = 'External SSL Certificates';
      local sslKubeconfigDesc = 'Kubeconfig Certificates';
      local sslK8sFileDesc = 'Internal Kubernetes Certificates';
      local sslK8sSecretDesc = 'Kubernetes Secret Certificates';
      local colors = [$._config.grafanaDashboards.color.red, $._config.grafanaDashboards.color.orange, $._config.grafanaDashboards.color.green];

      /* Template  for certificate table */
      local ssl_exporter_table(title, ssl_metric, columns) =
        table.new(
          title=title,
          datasource='$datasource',
          sort={ col: 3 },
          styles=[
                   { pattern: 'Time', type: 'hidden' },
                   { pattern: '__name__', type: 'hidden' },
                   { pattern: 'pod', type: 'hidden' },
                   { pattern: 'job', type: 'hidden' },
                   { pattern: 'endpoint', type: 'hidden' },
                   { pattern: 'namespace', type: 'hidden' },
                   { pattern: 'prometheus', type: 'hidden' },
                   { pattern: 'container', type: 'hidden' },
                   { pattern: 'prometheus_replica', type: 'hidden' },
                   { pattern: 'service', type: 'hidden' },
                   { alias: 'Serial No ', pattern: 'serial_no' },
                 ]
                 + columns
                 + [{ alias: 'TTL', pattern: 'Value', type: 'number', colors: colors, colorMode: 'cell', thresholds: [0, 8 * 24 * 60 * 60], unit: 's', decimals: 0 }]
        )
        .addTarget(
          prometheus.target(
            format='table',
            instant=true,
            expr=ssl_metric
          )
        );

      local externalCerts = ssl_exporter_table(
        title=sslExternalDesc,
        ssl_metric='ssl_cert_not_after{ job=~"$job", cluster="$cluster" } - time()',
        columns=
        [
          { alias: 'Instance', pattern: 'instance', type: 'string' },
          { alias: 'CN', pattern: 'cn', type: 'string' },
          { alias: 'Issuer CN', pattern: 'issuer_cn', type: 'string' },
          { alias: 'DNS Names', pattern: 'dnsnames', type: 'string' },
        ]
      );

      local k8sKubeconfig = ssl_exporter_table(
        title=sslKubeconfigDesc,
        ssl_metric='ssl_kubeconfig_cert_not_after{ job=~"$job", cluster="$cluster" } - time()',
        columns=
        [
          { pattern: 'dnsnames', type: 'hidden' },
          { pattern: 'instance', type: 'hidden' },
          { alias: 'Name', pattern: 'name', type: 'string' },
          { alias: 'CN', pattern: 'cn', type: 'string' },
          { alias: 'Issuer CN', pattern: 'issuer_cn', type: 'string' },
          { alias: 'Kubeconfig', pattern: 'kubeconfig', type: 'string' },
        ]
      );

      local k8sFiles = ssl_exporter_table(
        title=sslK8sFileDesc,
        ssl_metric='ssl_file_cert_not_after{ job=~"$job", cluster="$cluster" }* on(pod) group_left(node) kube_pod_info{ cluster="$cluster"} - time()',
        columns=
        [
          { pattern: 'dnsnames', type: 'hidden' },
          { pattern: 'instance', type: 'hidden' },
          { alias: 'CN', pattern: 'cn', type: 'string' },
          { alias: 'Node', pattern: 'node', type: 'string' },
          { alias: 'Issuer CN', pattern: 'issuer_cn', type: 'string' },
          { alias: 'Kubeconfig', pattern: 'kubeconfig', type: 'string' },
        ]
      );

      local k8sSecrets = ssl_exporter_table(
        title=sslK8sSecretDesc,
        ssl_metric='ssl_kubernetes_cert_not_after{ job=~"$job", cluster="$cluster" } - time()',
        columns=
        [
          { alias: 'CN', pattern: 'cn', type: 'string' },
          { alias: 'Issuer CN', pattern: 'issuer_cn', type: 'string' },
          { alias: 'DNS Names', pattern: 'dnsnames', type: 'string' },
        ]
      );

      local panels = [
        row.new('Overview') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        totalUniqueCerts { gridPos: { x: 0, y: 1, w: 6, h: 6 } },
        totalProbeTargets { gridPos: { x: 6, y: 1, w: 6, h: 6 } },
        failedSSLCount { gridPos: { x: 12, y: 1, w: 6, h: 6 } },
        nearingExpiryCount { gridPos: { x: 18, y: 1, w: 6, h: 6 } },

        row.new('Failed SSL Connects') { gridPos: { x: 0, y: 7, w: 6, h: 1 } },
        failedSSLConnect { gridPos: { x: 0, y: 8, w: 24, h: 6 } },

        row.new(sslExternalDesc) { gridPos: { x: 0, y: 14, w: 40, h: 1 } },
        externalCerts { gridPos: { x: 0, y: 15, w: 48, h: 8 } },

        row.new(sslKubeconfigDesc, collapse=true) { gridPos: { x: 0, y: 23, w: 40, h: 1 } }
        .addPanel(k8sKubeconfig { tooltip+: { sort: 2 } }, { x: 0, y: 24, w: 40, h: 8 }),

        row.new(sslK8sFileDesc, collapse=true) { gridPos: { x: 0, y: 32, w: 40, h: 1 } }
        .addPanel(k8sFiles { tooltip+: { sort: 2 } }, { x: 0, y: 33, w: 40, h: 8 }),

        row.new(sslK8sSecretDesc, collapse=true) { gridPos: { x: 0, y: 41, w: 40, h: 1 } }
        .addPanel(k8sSecrets { tooltip+: { sort: 2 } }, { x: 0, y: 40, w: 42, h: 8 }),
      ];

      dashboard.new(
        'SSL Certificates',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.sslExporter,
      )
      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(node_uname_info, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(ssl_probe_success{cluster="$cluster"}, job)'),
        $.grafanaTemplates.instanceTemplate('label_values({job=~"$job"}, instance)'),
      ])
      .addPanels(panels),
  },
}
