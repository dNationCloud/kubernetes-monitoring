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
      regex='',
      includeAll=true,
      multi=true,
      allValues=null,
      current=null,
    )::
      template.new(
        name=name,
        label=label,
        query=query,
        datasource=datasource,
        refresh=refresh,
        sort=sort,
        hide=hide,
        regex=regex,
        includeAll=includeAll,
        multi=multi,
        allValues=allValues,
        current=current,
      ),

    local baseTemplate = $.grafanaTemplates.baseTemplate,

    datasourceTemplate()::
      template.datasource(
        name='datasource',
        label='Datasource',
        query='prometheus',
        current='thanos',
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

    intervalTemplate(query)::
      template.interval(
        name='interval',
        label='Interval',
        query=query,
        current='All',
      ),

    alertGroupTemplate(query)::
      baseTemplate(
        query=query,
        name='alertgroup',
        label='Alert Group',
      ),

    severityTemplate(query)::
      baseTemplate(
        query=query,
        name='severity',
        label='Severity',
      ),

    targetTemplate(query, hide='', multi=true, includeAll=true, current='All')::
      baseTemplate(
        name='target',
        label='Service Target',
        query=query,
        includeAll=includeAll,
        multi=multi,
        hide=hide,
        current=current,
      ),

    clusterTemplate(query, hide='', multi=false, includeAll=false, current=null)::
      baseTemplate(
        name='cluster',
        label='Cluster',
        query=query,
        includeAll=includeAll,
        multi=multi,
        hide=hide,
        current=current,
      ),

    instanceTemplate(query, label='Instance', regex='')::
      baseTemplate(
        name='instance',
        label=label,
        query=query,
        regex=regex,
      ),

    nodeTemplate(query)::
      baseTemplate(
        name='instance',
        label='Nodes',
        query=query,
      ),

    namespaceTemplate(query, includeAll=true, multi=true)::
      baseTemplate(
        name='namespace',
        label='Namespace',
        query=query,
        includeAll=includeAll,
        multi=multi,
      ),

    podTemplate(query, hide='', includeAll=true, multi=true)::
      baseTemplate(
        name='pod',
        label='Pod',
        query=query,
        hide=hide,
        includeAll=includeAll,
        multi=multi,
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

    jobNameTemplate(query, includeAll=true, multi=true)::
      baseTemplate(
        name='job_name',
        label='Job name',
        query=query,
        includeAll=includeAll,
        multi=multi,
      ),

    jobTemplate(query, hide='', current=null, regex='', includeAll=true, multi=true)::
      baseTemplate(
        name='job',
        label='Job',
        query=query,
        hide=hide,
        current=current,
        regex=regex,
        includeAll=includeAll,
        multi=multi,
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

    retentionTemplate()::
      template.text(
        name='retention',
        label='Retention',
      ) {
        current: {
          selected: false,
          text: '300',
          value: '300',
        },
      },


    viewByTemplate(query)::
      template.custom(
        name='view',
        label='View by',
        query=query,
        current='container',
      ),

    diskFileSystemsTemplate()::
      template.custom(
        name='diskfs',
        label='Disk FileSystems',
        query='ext2,ext3,ext4,btrfs,vfat,fuseblk,jfs,zfs,reiserfs,f2fs,xfs',
        hide='variable',
        includeAll=true,
        multi=false,
        current='All',
      ),

    masterInstanceTemplate()::
      baseTemplate(
        name='masterInstance',
        label='Master Instance',
        query='label_values(master_uname_info{cluster="$cluster"}, instance)',
        hide='variable',
      ),

    workerInstanceTemplate()::
      baseTemplate(
        name='workerInstance',
        label='Worker Instance',
        query='label_values(worker_uname_info{cluster="$cluster"}, instance)',
        hide='variable',
      ),
  },
}
