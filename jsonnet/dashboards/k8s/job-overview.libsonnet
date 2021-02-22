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

/* K8s job overview dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local template = grafana.template;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+:: {
    'job-overview':
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
          query='label_values(kube_job_info, cluster)',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      local namespaceTemplate =
        template.new(
          name='namespace',
          label='Namespace',
          datasource='$datasource',
          query='label_values(kube_job_info{cluster=~"$cluster"}, namespace)',
          refresh=$._config.grafanaDashboards.templateRefresh,
          sort=$._config.grafanaDashboards.templateSort,
          includeAll=true,
          multi=true,
        );

      local jobTemplate =
        template.new(
          name='job',
          label='Job',
          datasource='$datasource',
          query='label_values(kube_job_info{cluster=~"$cluster", namespace=~"$namespace"}, job)',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          includeAll=true,
          multi=true,
        );

      local colors = [$._config.grafanaDashboards.color.green, $._config.grafanaDashboards.color.orange, $._config.grafanaDashboards.color.red];
      local valueMaps = [
        { text: 'Succeeded', value: 1 },
        { text: 'Active', value: 2 },
        { text: 'Failed', value: 3 },
      ];

      local jobsTable =
        table.new(
          title='Jobs',
          datasource='$datasource',
          sort={ col: 4, desc: true },
          styles=[
            { pattern: 'Time', type: 'hidden' },
            { alias: 'Status', pattern: 'Value', colors: colors, colorMode: 'cell', type: 'string', thresholds: [3, 3], valueMaps: valueMaps, mappingType: 1 },
            { alias: 'Job name', pattern: 'job_name', type: 'string' },
            { alias: 'Owner', pattern: 'owner_name', link: true, linkTooltip: 'Detail', linkUrl: '/d/%s?var-container=${__cell_3}&var-namespace=${__cell_2}&var-view=container&var-search=&%s' % [$._config.grafanaDashboards.ids.containerDetail, $._config.grafanaDashboards.dataLinkCommonArgs] },
            { alias: 'Namespace', pattern: 'namespace', type: 'string' },
          ]
        )
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr=|||
              sum by (job_name, namespace) (kube_job_status_succeeded{cluster=~"$cluster", namespace=~"$namespace", job=~"$job"} * 1) * on(job_name, namespace) group_left(owner_name) kube_job_owner{cluster=~"$cluster", namespace=~"$namespace", job=~"$job"} +
              sum by (job_name, namespace) (kube_job_status_active{cluster=~"$cluster", namespace=~"$namespace", job=~"$job"} * 2) * on(job_name, namespace) group_left(owner_name) kube_job_owner{cluster=~"$cluster", namespace=~"$namespace", job=~"$job"} +
              sum by (job_name, namespace) (kube_job_status_failed{cluster=~"$cluster", namespace=~"$namespace", job=~"$job"} * 3) * on(job_name, namespace) group_left(owner_name) kube_job_owner{cluster=~"$cluster", namespace=~"$namespace", job=~"$job"}
            |||),
          ]
        );

      dashboard.new(
        'Job',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sOverview,
        uid=$._config.grafanaDashboards.ids.jobOverview,
      )
      .addTemplates([datasourceTemplate, clusterTemplate, namespaceTemplate, jobTemplate])
      .addPanels(
        [
          row.new('Jobs') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          jobsTable { gridPos: { x: 0, y: 1, w: 24, h: 23 } },
        ]
      ),
  },
}
