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

/* Common grafana templates */
local grafana = import 'grafonnet/grafana.libsonnet';
local template = grafana.template;

{
  grafanaTemplates: {

    baseTemplate(
      name,
      label,
      query,
      datasource='$datasource',
      refresh=$._config.grafanaDashboards.templateRefresh,
      sort=$._config.grafanaDashboards.templateSort,
      hide='',
      includeAll=true,
      multi=true,
      allValues=null,
    )::
      template.new(
        name=name,
        label=label,
        query=query,
        datasource=datasource,
        refresh=refresh,
        sort=sort,
        hide=hide,
        includeAll=includeAll,
        multi=multi,
        allValues=allValues,
      ),

    local baseTemplate = $.grafanaTemplates.baseTemplate,

    datasourceTemplate()::
      template.datasource(
        name='datasource',
        label='Datasource',
        query='prometheus',
        current=null,
      ),

    alertManagerTemplate()::
      template.datasource(
        name='alertmanager',
        label='Alertmanager',
        query='camptocamp-prometheus-alertmanager-datasource',
        current=null,
        hide='variable',
      ),

    datasourceLogsTemplate(hide='')::
      template.datasource(
        name='datasource_logs',
        label='Logs datasource',
        query='loki',
        current=null,
        hide=hide,
      ),

    alertGroupTemplate(query)::
      baseTemplate(
        datasource='$alertmanager',
        query=query,
        name='alertgroup',
        label='Alert Group',
      ),

    severityTemplate(query)::
      baseTemplate(
        datasource='$alertmanager',
        query=query,
        name='severity',
        label='Severity',
      ),

    clusterTemplate(query)::
      baseTemplate(
        name='cluster',
        label='Cluster',
        query=query,
        hide='variable',
        includeAll=false,
        multi=false,
      ),

    instanceTemplate(query, label='Instance')::
      baseTemplate(
        name='instance',
        label=label,
        query=query,
      ),

    nodeTemplate(query)::
      baseTemplate(
        name='instance',
        label='Nodes',
        query=query,
      ),

    namespaceTemplate(query)::
      baseTemplate(
        name='namespace',
        label='Namespace',
        query=query,
      ),

    podTemplate(query, hide='')::
      baseTemplate(
        name='pod',
        label='Pod',
        query=query,
        hide=hide,
      ),

    containerTemplate(query)::
      baseTemplate(
        name='container',
        label='Container',
        query=query,
      ),

    daemonsetTemplate(query)::
      baseTemplate(
        name='daemonset',
        label='DaemonSet',
        query=query,
      ),

    deploymentTemplate(query)::
      baseTemplate(
        name='deployment',
        label='Deployment',
        query=query,
      ),

    jobNameTemplate(query)::
      baseTemplate(
        name='job_name',
        label='Job name',
        query=query,
      ),

    jobTemplate(query, hide='')::
      baseTemplate(
        name='job',
        label='Job',
        query=query,
        hide=hide,
      ),

    pvcTemplate(query)::
      baseTemplate(
        name='pvc',
        label='PVC',
        query=query,
      ),

    statefulsetTemplate(query)::
      baseTemplate(
        name='statefulset',
        label='StatefulSet',
        query=query,
      ),

    workloadTemplate(query)::
      baseTemplate(
        name='workload',
        label='Workload',
        query=query,
      ),

    workloadTypeTemplate(query)::
      baseTemplate(
        name='workload_type',
        label='Workload Type',
        query=query,
        allValues='workaround',  // workaround for pods without workload type
      ),

    searchTemplate()::
      template.text(
        name='search',
        label='Logs Search',
      ),

    viewByTemplate(query)::
      template.custom(
        name='view',
        label='View by',
        query=query,
        current='container',
      ),

    masterNameTemplate()::
      baseTemplate(
        name='masterName',
        label='Master Name',
        query='label_values(kube_node_role{cluster=~"$cluster", role="master"}, node)',
        hide='variable',
        includeAll=false,
        multi=false,
      ),

    masterInstanceTemplate()::
      baseTemplate(
        name='masterInstance',
        label='Master Instance',
        query='label_values(node_uname_info{cluster=~"$cluster", nodename=~"$masterName"}, instance)',
        hide='variable',
        includeAll=false,
        multi=false,
      ),
  },
}
