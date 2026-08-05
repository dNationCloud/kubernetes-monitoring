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
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local variable = grafana.dashboard.variable;

{
  grafanaTemplates: {

    local hideMap(hide) =
      if hide == 'variable' then 2
      else if hide == 'label' then 1
      else 0,

    local refreshMode(refresh) =
      if refresh == 'onTime' then variable.query.refresh.onTime()
      else if refresh == 'onLoad' then variable.query.refresh.onLoad()
      else error "templateRefresh must be 'onTime' or 'onLoad', got: %s" % refresh,

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
      variable.query.new(name, query)
      + variable.query.generalOptions.withLabel(label)
      + variable.query.withDatasource('prometheus', datasource)
      + refreshMode(refresh)
      + variable.query.withSort(sort)
      + variable.query.withRegex(regex)
      + variable.query.selectionOptions.withIncludeAll(includeAll, allValues)
      + variable.query.selectionOptions.withMulti(multi)
      + { hide: hideMap(hide) }
      + (if current != null then variable.query.generalOptions.withCurrent(current) else {}),

    local baseTemplate = $.grafanaTemplates.baseTemplate,

    datasourceTemplate()::
      variable.datasource.new('datasource', 'prometheus')
      + variable.datasource.generalOptions.withLabel('Datasource')
      + variable.datasource.generalOptions.withCurrent('thanos'),

    alertManagerTemplate()::
      variable.datasource.new('alertmanager', 'camptocamp-prometheus-alertmanager-datasource')
      + variable.datasource.generalOptions.withLabel('Alertmanager')
      + { hide: hideMap('variable') },

    datasourceLogsTemplate(hide='')::
      variable.datasource.new('datasource_logs', 'loki')
      + variable.datasource.generalOptions.withLabel('Logs datasource')
      + { hide: hideMap(hide) },

    intervalTemplate(query)::
      variable.interval.new('interval', [std.stripChars(v, ' ') for v in std.split(query, ',')])
      + variable.interval.generalOptions.withLabel('Interval')
      + variable.interval.generalOptions.withCurrent('All'),

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
      variable.textbox.new('search')
      + variable.textbox.generalOptions.withLabel('Logs Search'),

    retentionTemplate()::
      variable.textbox.new('retention', '300')
      + variable.textbox.generalOptions.withLabel('Retention'),

    viewByTemplate(query)::
      variable.custom.new('view', std.split(query, ','))
      + variable.custom.generalOptions.withLabel('View by')
      + variable.custom.generalOptions.withCurrent('container'),

    diskFileSystemsTemplate()::
      variable.custom.new('diskfs', std.split('ext2,ext3,ext4,btrfs,vfat,fuseblk,jfs,zfs,reiserfs,f2fs,xfs', ','))
      + variable.custom.generalOptions.withLabel('Disk FileSystems')
      + variable.custom.selectionOptions.withIncludeAll(true)
      + variable.custom.selectionOptions.withMulti(false)
      + variable.custom.generalOptions.withCurrent('All')
      + { hide: hideMap('variable') },

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
