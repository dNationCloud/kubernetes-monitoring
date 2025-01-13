/*
  Copyright 2024 The dNation Kubernetes Monitoring Authors. All Rights Reserved.
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
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local prometheus = g.query.prometheus;
local stat = g.panel.stat;
local table = g.panel.table;
local timeSeries = g.panel.timeSeries;
local var = g.dashboard.variable;
local row = g.panel.row;
{
    local hr='(Time|container|endpoint|job|namespace|prometheus.*|service|pod)',

    local failedSSLConnectTable = $.gTables.threshold(
        title="Failed SSL Connects",
        query='ssl_cert_not_after{ job=~"$job", cluster="$cluster" } - time()',
        steps= $.gTableSteps.transparent,
        unit='s',
        hideRegexp=hr,
    ),
    local sslExporterTable(title,query) = $.gTables.valueThreshold(
        title=title,
        query=query,
        steps = $.gTableSteps.standard(null,24*60*60,7*24*60*60),
        unit='s',
        hideRegexp=hr,
    )
     + table.queryOptions.withTransformations([
        table.queryOptions.transformation.withId('organize')
        + table.queryOptions.transformation.withOptions({
            renameByName: {
              Value: "Expires In",
              cluster: "Cluester",
              cn: "CN",
              issuer_cn: "IssuerCN",
              serial_no: "Serial No."
            },
        }
        )
     ],)
     
    ,
    local sslExternalDesc = 'External SSL Certificates',
    local sslKubeconfigDesc = 'Kubeconfig Certificates',
    local sslK8sFileDesc = 'Internal Kubernetes Certificates',
    local sslK8sSecretDesc = 'Kubernetes Secret Certificates',
    grafanaDashboards+:: {
    'ssl-exporter-new':
    local panels = {
        totalUniqueCerts: $.gStatPanels.fixed(
            title='Total Unique Certificates',
            query='count(max(ssl_cert_not_after{cluster="$cluster", job=~"$job"}) by (issuer_cn, serial_no))'
            ),
        totalProbeTargets: $.gStatPanels.fixed(
            title='Total Probe Targets',
            query='count(ssl_probe_success{cluster="$cluster"})',
        ),
        failedSSLCount: $.gStatPanels.threshold(
            title='Expired/Failed Certificates',
            query='(count(up{job=~"$job", cluster="$cluster"}==0) OR on() vector(0))+(count(ssl_probe_success{cluster="$cluster"}==0) OR on() vector(0))+(count((ssl_cert_not_after{cluster="$cluster"}-time())<0) OR on() vector(0))+\n            (count((ssl_file_not_after{cluster="$cluster"}-time())<0) OR on() vector(0))+\n            (count((ssl_kubeconfig_cert_not_after{cluster="$cluster"}-time())<0) OR on()vector(0))+(count((ssl_kubernetes_cert_not_after{cluster="$cluster"}-time())<0) OR on()vector(0))',
            steps=[
                stat.standardOptions.threshold.step.withValue(0)
                + stat.standardOptions.threshold.step.withColor('green'),
                stat.standardOptions.threshold.step.withValue(1)
                + stat.standardOptions.threshold.step.withColor('red'),
                ],
        ),
        nearingExpiryCount : $.gStatPanels.threshold(
            title='Certificates Nearing Expiration',
            query='(count(0<(ssl_cert_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0))+(count(0<(ssl_file_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0))+(count(0<(ssl_kubeconfig_cert_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0))+(count(0<(ssl_kubernetes_cert_not_after{cluster="$cluster"}-time())<8*24*60*60) OR on() vector(0))',
            steps=[
                stat.standardOptions.threshold.step.withValue(0)
                + stat.standardOptions.threshold.step.withColor('green'),
                stat.standardOptions.threshold.step.withValue(1)
                + stat.standardOptions.threshold.step.withColor('orange'),
                ],

        ),
        failedSSLConnect: failedSSLConnectTable
        ,
        externalCerts : sslExporterTable(
            title=sslExternalDesc,
            query='ssl_cert_not_after{ job=~"$job", cluster="$cluster" } - time()'
            ),
        k8sKubeconfigCerts : sslExporterTable(
            title=sslKubeconfigDesc,
            query='ssl_kubeconfig_cert_not_after{ job=~"$job", cluster="$cluster" } - time()',
            ),
        k8sFiles: sslExporterTable(
            title=sslK8sFileDesc,
            query='ssl_file_cert_not_after{ job=~"$job", cluster="$cluster" }* on(pod) group_left(node) kube_pod_info{ cluster="$cluster"} - time()',
            ),
        k8sSecrets: sslExporterTable(
            title=sslK8sSecretDesc,
            query='ssl_kubernetes_cert_not_after{ job=~"$job", cluster="$cluster" } - time()',
            ),
    };

    local grid =
    g.util.grid.makeGrid(
        [
        row.new('Overview')
        + row.withPanels([
            panels.totalUniqueCerts,
            panels.totalProbeTargets,
            panels.failedSSLCount,
            panels.nearingExpiryCount
        ])],panelWidth=6, panelHeight=6, startY=0)
    + g.util.grid.makeGrid([
         row.new('Failed SSL Connects')
         + row.withPanels([
            panels.failedSSLConnect
         ]),
         row.new(sslExternalDesc)
         + row.withPanels([
            panels.externalCerts,
        ]),
         row.new(sslKubeconfigDesc)
         + row.withCollapsed()
         + row.withPanels([
            panels.k8sKubeconfigCerts,
        ]),
         row.new(sslK8sFileDesc)
         + row.withCollapsed()
         + row.withPanels([
            panels.k8sFiles,
        ]),
         row.new(sslK8sSecretDesc)
         + row.withCollapsed()
         + row.withPanels([
            panels.k8sSecrets,
        ])],panelWidth=24, panelHeight=6, startY=7);
    // hack: g.util has a makeGrid function, however it supports only panels of equal width
    local rowfunc(row) = g.util.grid.wrapPanels([row.content],24,1,row.y-1) + g.util.grid.wrapPanels(
        row.content.panels,
        row.w,
        row.h,
        row.y
      );

    g.dashboard.new('SSL Certificates')
    + g.dashboard.withUid($._config.grafanaDashboards.ids.sslExporter)
    + g.dashboard.withEditable($._config.grafanaDashboards.editable)
    + g.dashboard.withRefresh($._config.grafanaDashboards.refresh)
    + g.dashboard.time.withFrom($._config.grafanaDashboards.time_from)
    + g.dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
    + g.dashboard.withVariables([
        $.gVariables.datasource(),
        $.gVariables.cluster('node_uname_info'),
        $.gVariables.job('ssl_probe_success{cluster="$cluster"}'),
        $.gVariables.instance('{job=~"$job"}')
        ])
    + g.dashboard.withPanels(grid)
    },

}
