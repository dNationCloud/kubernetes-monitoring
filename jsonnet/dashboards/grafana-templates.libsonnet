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
      hide=0,
      includeAll=true,
      multi=true,
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

    datasourceLogsTemplate()::
      template.datasource(
        name='datasource_logs',
        label='Logs datasource',
        query='loki',
        current=null,
        hide='variable',
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

    instanceTemplate(query)::
      baseTemplate(
        name='instance',
        label='Instance',
        query=query,
        hide='variable',
        includeAll=false,
        multi=false,
      ),

    namespaceTemplate(query)::
      baseTemplate(
        name='namespace',
        label='Namespace',
        query=query,
      ),

    podTemplate(query)::
      baseTemplate(
        name='pod',
        label='Pod',
        query=query,
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

    jobTemplate(query)::
      baseTemplate(
        name='job_name',
        label='Job name',
        query=query,
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
  },
}
