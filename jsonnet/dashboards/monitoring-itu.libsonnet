/* ITU L0 dashboard - stats panel that aggregates OpenStack and K8s health */
/* Feature flag ITUMonitoring has to be enabled to render this dashboard */

local grafana = (import 'grafonnet/grafana.libsonnet');
local dashboard = grafana.dashboard;
local statPanel = grafana.statPanel;
local row = grafana.row;
local link = grafana.link;
local template = grafana.template;

{
  grafanaDashboards+::

    if $.isITUMonitoring() then
      {
        'itu-monitoring':
          local dNationLink =
            link.dashboards(
              title='dNation - Making Cloud Easy',
              tags=[],
              icon='cloud',
              url='https://www.dNation.cloud/',
              type='link',
              targetBlank=true,
            );

          local maxWarnings = $._config.grafanaDashboards.constants.maxWarnings;

          /** Expression consists from the following:
           *  - Health of openstack cloud (based on openstack_.*_up metrics)
           *  - Health of K8s cluster (based on node-exporter and ALERTS)
           */
          local expr = |||
            (
              1 - min({__name__=~"openstack_.*_up", instance=~"$cloud"})
            ) * (%(maxWarnings)d)
            +
            (
              (sum(up{job=~"node-exporter", cluster="%(cluster)s"}) or on() vector(0)) == bool 0
            ) * (-1)
            +
            sum(
              ALERTS{
                alertname!="Watchdog",
                cluster="%(cluster)s",
                alertstate="firing",
                severity="warning",
                alertgroup=~"%(groupCluster)s|%(groupApp)s"
              } OR on() vector(0)
            )
            +
            sum(
              ALERTS{
                alertname!="Watchdog",
                cluster="%(cluster)s",
                alertstate="firing",
                severity="critical",
                alertgroup=~"%(groupCluster)s|%(groupApp)s"
              } OR on() vector(0)
            ) * %(maxWarnings)d
          |||;
          local mappings = [
            { from: -1, text: 'Down', to: -1, type: 2, value: '' },
            { from: 0, text: 'OK', to: 0, type: 2, value: '' },
            { from: 1, text: 'Warning', to: maxWarnings - 1, type: 2, value: '' },
            { from: maxWarnings, text: 'Critical', to: $._config.grafanaDashboards.constants.infinity, type: 2, value: '' },
          ];
          local ituStatPanel =
            statPanel.new(
              title='ITU Monitoring',
              datasource='$datasource',
              unit='none',
              colorMode='background',
              graphMode='none',
              decimals=null,
            )
            .addThresholds($.grafanaThresholds({
              operator: '>=',
              lowest: 0,
              warning: 1,
              critical: maxWarnings,
            }))
            .addTarget(
              {
                type: 'single',
                instant: true,
                expr: expr %
                      {
                        cluster: '$cluster',
                        groupCluster: $._config.prometheusRules.alertGroupCluster,
                        groupApp: $._config.prometheusRules.alertGroupClusterApp,
                        maxWarnings: maxWarnings,
                      },
              }
            )
            .addMappings(mappings)
            .addDataLinks(
              $.updateDataLinksCommonArgs(
                [{ title: 'OpenStack Kubernetes', url: '/d/%s?%s?var-cloud=$cloud' % [$._config.grafanaDashboards.ids.openstackK8s, $._config.grafanaDashboards.dataLinkCommonArgs] }]
              )
            );

          local cloudTemplate =
            template.new(
              name='cloud',
              label='Cloud',
              query='label_values(openstack_identity_up, instance)',
              datasource='$datasource',
              sort=$._config.grafanaDashboards.templateSort,
              refresh=$._config.grafanaDashboards.templateRefresh,
              multi=false,
              includeAll=false,
            );

          dashboard.new(
            'ITU Monitoring',
            editable=$._config.grafanaDashboards.editable,
            graphTooltip=$._config.grafanaDashboards.tooltip,
            refresh=$._config.grafanaDashboards.refresh,
            time_from=$._config.grafanaDashboards.time_from,
            tags=$._config.grafanaDashboards.tags.openstack + $._config.grafanaDashboards.tags.k8sMonitoringMain,
            uid=$._config.grafanaDashboards.ids.ITUMonitoring,
          )
          .addLink(dNationLink)
          .addTemplates([
            $.grafanaTemplates.datasourceTemplate(),
            $.grafanaTemplates.alertManagerTemplate(),
            $.grafanaTemplates.clusterTemplate('label_values(openstack_identity_up, cluster)'),
            cloudTemplate,
          ])
          .addPanels([
            row.new('ITU Monitoring') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
            ituStatPanel { gridPos: { x: 0, y: 1, w: 4, h: 3 } },
          ]),
      } else {},
}
