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

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local row = grafana.row;
local table = grafana.tablePanel;

{
  grafanaDashboards+::
    local overviewDashboard(dashboardUid, dashboardName, mainTemplate, grafanaTemplates, customParams) = {
      local overviewTable =
        local templatePanel = mainTemplate.panel;
        table.new(
          title=templatePanel.title,
          datasource=templatePanel.datasource,
          sort=templatePanel.sort,
          description=templatePanel.description,
          styles=templatePanel.styles,
        )
        .addTransformations(templatePanel.transformations)
        .addTargets(
          [
            prometheus.target(format='table', instant=true, expr=expr)
            for expr in templatePanel.expr
          ]
        )
        { gridPos: templatePanel.gridPos },

      dashboard:
        dashboard.new(
          dashboardName,
          editable=$._config.grafanaDashboards.editable,
          graphTooltip=$._config.grafanaDashboards.tooltip,
          refresh=$._config.grafanaDashboards.refresh,
          time_from=$._config.grafanaDashboards.time_from,
          tags=$._config.grafanaDashboards.tags.k8sOverview,
          uid=dashboardUid,
        )
        .addTemplates([
          $.grafanaTemplates.datasourceTemplate(),
        ] + grafanaTemplates)
        .addPanels(
          [
            row.new(customParams.rowName) { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
            overviewTable,
          ]
        ),
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
        $.grafanaTemplates.namespaceTemplate('label_values(kube_pod_container_info{cluster=~"$cluster"}, namespace)'),
        $.grafanaTemplates.podTemplate('label_values(kube_pod_container_info{cluster=~"$cluster", namespace=~"$namespace"}, pod)'),
      ],
    ) +

    $.createOverviewDashboards(
      jsonName='job-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.jobOverview,
      dashboardName='Job',
      rowName='Jobs',
      templateName='jobOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.jobNameTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_job_info, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_job_info{cluster=~"$cluster"}, namespace)'),
      ],
    ) +

    $.createOverviewDashboards(
      jsonName='daemonset-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.daemonSetOverview,
      dashboardName='DaemonSet',
      rowName='DaemonSets',
      templateName='daemonSetOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.daemonsetTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_daemonset_status_desired_number_scheduled, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_daemonset_status_desired_number_scheduled{cluster=~"$cluster"}, namespace)'),
      ],
    ) +

    $.createOverviewDashboards(
      jsonName='deployment-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.deploymentOverview,
      dashboardName='Deployment',
      rowName='Deployments',
      templateName='deploymentOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.deploymentTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_deployment_status_replicas, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_deployment_status_replicas{cluster=~"$cluster"}, namespace)'),
      ],
    ) +

    $.createOverviewDashboards(
      jsonName='pod-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.podOverview,
      dashboardName='Pod',
      rowName='Pods',
      templateName='podOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.podTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_pod_info, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_pod_info{cluster=~"$cluster"}, namespace)'),
      ],
    ) +

    $.createOverviewDashboards(
      jsonName='statefulset-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.statefulSetOverview,
      dashboardName='StatefulSet',
      rowName='StatefulSets',
      templateName='statefulSetOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.statefulsetTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_statefulset_status_replicas, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_statefulset_status_replicas{cluster=~"$cluster"}, namespace)'),
      ],
    ) +

    $.createOverviewDashboards(
      jsonName='pvc-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.pvcOverview,
      dashboardName='PVC',
      rowName='Persistent Volumes',
      templateName='pvcOverviewTable',
      customizableGrafanaTemplateFunction=$.grafanaTemplates.pvcTemplate,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_persistentvolumeclaim_info, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_persistentvolumeclaim_info{cluster=~"$cluster"}, namespace)'),
      ],
    ) +

    $.createOverviewDashboards(
      jsonName='node-overview',
      dashboardFunction=overviewDashboard,
      dashboardUid=$._config.grafanaDashboards.ids.nodeOverview,
      dashboardName='Node',
      rowName='Nodes',
      templateName='nodeOverviewTable',
      customizableGrafanaTemplateFunction=null,
      grafanaTemplates=[
        $.grafanaTemplates.clusterTemplate('label_values(kube_node_status_condition, cluster)'),
        $.grafanaTemplates.namespaceTemplate('label_values(kube_persistentvolumeclaim_info{cluster=~"$cluster"}, namespace)'),
      ],
    ),

}
