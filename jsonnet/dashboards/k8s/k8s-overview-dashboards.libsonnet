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

/* K8s L2 k8s overview dashboards */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local table = grafana.panel.table;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+::
    local v1Thresholds(ths, cols) = {
      mode: 'absolute',
      steps: [{ color: cols[0], value: null }] + [{ color: cols[i + 1], value: ths[i] } for i in std.range(0, std.length(ths) - 1)],
    };

    local v1ValueMaps(vms) = [{ type: 'value', options: { [std.toString(vm.value)]: { text: vm.text } for vm in vms } }];

    local v1RangeMaps(rms) = [
      { type: 'range', options: { from: rms[i].from, to: rms[i].to, result: { text: rms[i].text, index: i } } }
      for i in std.range(0, std.length(rms) - 1)
    ];

    local styleToOverride(s) = {
      matcher: { id: 'byName', options: s.pattern },
      properties:
        (if std.objectHas(s, 'type') && s.type == 'hidden' then [{ id: 'custom.hidden', value: true }] else [])
        + (if std.objectHas(s, 'alias') then [{ id: 'displayName', value: s.alias }] else [])
        + (if std.objectHas(s, 'unit') then [{ id: 'unit', value: s.unit }] else [])
        + (if std.objectHas(s, 'decimals') then [{ id: 'decimals', value: s.decimals }] else [])
        + (if std.objectHas(s, 'link') && s.link then [{ id: 'links', value: [{ title: (if std.objectHas(s, 'linkTooltip') then s.linkTooltip else ''), url: s.linkUrl }] }] else [])
        + (if std.objectHas(s, 'colorMode') then [{ id: 'custom.cellOptions', value: { type: 'color-background' } }] else [])
        + (if std.objectHas(s, 'valueMaps') then [{ id: 'mappings', value: v1ValueMaps(s.valueMaps) }] else [])
        + (if std.objectHas(s, 'rangeMaps') then [{ id: 'mappings', value: v1RangeMaps(s.rangeMaps) }] else [])
        + (if std.objectHas(s, 'thresholds') && std.objectHas(s, 'colors') then [{ id: 'thresholds', value: v1Thresholds(s.thresholds, s.colors) }] else []),
    };

    local defaultSortBy = {
      Containers: [{ displayName: 'Restarts', desc: true }],
      Jobs: [{ displayName: 'Status', desc: true }],
      Pods: [{ displayName: 'Status', desc: true }],
      DaemonSets: [{ displayName: 'Ready', desc: true }],
      Deployments: [{ displayName: 'Available', desc: true }],
      StatefulSets: [{ displayName: 'Ready', desc: true }],
      'Persistent Volumes': [{ displayName: 'Capacity', desc: true }],
      Nodes: [{ displayName: 'Ready', desc: true }],
    };

    local overviewDashboard(dashboardUid, dashboardName, mainTemplate, grafanaTemplates, customParams) = {
      local tp = mainTemplate.panel,

      local overviewTable =
        table.new(tp.title)
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + (if std.objectHas(tp, 'description') then table.panelOptions.withDescription(tp.description) else {})
        + (if std.objectHas(tp, 'transformations') && tp.transformations != null && std.length(tp.transformations) > 0 then table.queryOptions.withTransformations(tp.transformations) else {})
        + table.standardOptions.withOverrides([styleToOverride(s) for s in $.updateDataLinksCommonArgs(tp.styles, tableLink=true)])
        + table.queryOptions.withTargets([prometheus.withExpr(expr) + prometheus.withFormat('table') + prometheus.withInstant(true) for expr in tp.expr])
        + (if std.objectHas(defaultSortBy, customParams.rowName) then { options+: { sortBy: defaultSortBy[customParams.rowName] } } else {})
        + { gridPos: tp.gridPos },

      dashboard:
        dashboard.new(dashboardName)
        + dashboard.withUid(dashboardUid)
        + dashboard.withTags($._config.grafanaDashboards.tags.k8sOverview)
        + dashboard.withEditable($._config.grafanaDashboards.editable)
        + dashboard.withRefresh($._config.grafanaDashboards.refresh)
        + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
        + $._config.grafanaDashboards.tooltip
        + dashboard.withTimezone('browser')
        + dashboard.withVariables([$.grafanaTemplates.datasourceTemplate()] + grafanaTemplates)
        + dashboard.withPanels([
          row.new(customParams.rowName) + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          overviewTable,
        ]),
    };

    $.createOverviewDashboards(
      jsonName='container-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.containerOverview,
      dashboardName='Container',
      rowName='Containers',
      templateName='containerOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.containerTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_pod_container_info, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_pod_container_info{cluster="$cluster"}, namespace)'),
        $.grafanaTemplates.podTemplate('label_values(kube_pod_container_info{cluster="$cluster", namespace=~"$namespace"}, pod)'),
      ],
    )
    + $.createOverviewDashboards(
      jsonName='job-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.jobOverview,
      dashboardName='Job',
      rowName='Jobs',
      templateName='jobOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.jobNameTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_job_info, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_job_info{cluster="$cluster"}, namespace)'),
      ],
    )
    + $.createOverviewDashboards(
      jsonName='daemonset-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.daemonSetOverview,
      dashboardName='DaemonSet',
      rowName='DaemonSets',
      templateName='daemonSetOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.daemonsetTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_daemonset_status_desired_number_scheduled, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_daemonset_status_desired_number_scheduled{cluster="$cluster"}, namespace)'),
      ],
    )
    + $.createOverviewDashboards(
      jsonName='deployment-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.deploymentOverview,
      dashboardName='Deployment',
      rowName='Deployments',
      templateName='deploymentOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.deploymentTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_deployment_status_replicas, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_deployment_status_replicas{cluster="$cluster"}, namespace)'),
      ],
    )
    + $.createOverviewDashboards(
      jsonName='pod-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.podOverview,
      dashboardName='Pod',
      rowName='Pods',
      templateName='podOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.podTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_pod_info, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_pod_info{cluster="$cluster"}, namespace)'),
      ],
    )
    + $.createOverviewDashboards(
      jsonName='statefulset-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.statefulSetOverview,
      dashboardName='StatefulSet',
      rowName='StatefulSets',
      templateName='statefulSetOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.statefulsetTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_statefulset_status_replicas, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_statefulset_status_replicas{cluster="$cluster"}, namespace)'),
      ],
    )
    + $.createOverviewDashboards(
      jsonName='pvc-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.pvcOverview,
      dashboardName='PVC',
      rowName='Persistent Volumes',
      templateName='pvcOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.pvcTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_persistentvolumeclaim_info, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_persistentvolumeclaim_info{cluster="$cluster"}, namespace)'),
      ],
    )
    + $.createOverviewDashboards(
      jsonName='node-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.nodeOverview,
      dashboardName='Node',
      rowName='Nodes',
      templateName='nodeOverviewTable',
      customizableGrafanaTemplateFunction=null,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_node_status_condition, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_persistentvolumeclaim_info{cluster="$cluster"}, namespace)'),
      ],
    ),
}
