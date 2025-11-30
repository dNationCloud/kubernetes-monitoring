/* OpenStack L1 dashboard - two stats panels - OpenStack and K8s */
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
        'openstack-k8s':
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

          local getUid(defaultUid, obj, templateGroup) =
            if $.isAnyDefault([obj], templateGroup) then defaultUid else $.getCustomUid([defaultUid, obj.name]);

          local exprOpenstack = |||
            (
              1 - min({__name__=~"openstack_.*_up", instance=~"$cloud"})
            ) * (%(maxWarnings)d)
          |||;

          local exprK8s = |||
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
          local openStackStatPanel =
            statPanel.new(
              title='OpenStack Monitoring',
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
                expr: exprOpenstack %
                      {
                        maxWarnings: maxWarnings,
                      },
              }
            )
            .addMappings(mappings)
            .addDataLinks(
              $.updateDataLinksCommonArgs(
                [{ title: 'OpenStack Detail', url: '/d/%s?%s?var-cloud=$cloud' % [$._config.grafanaDashboards.ids.openstackDetail, $._config.grafanaDashboards.dataLinkCommonArgs] }]
              )
            );

          local k8sStatPanel =
            statPanel.new(
              title='Kubernetes Monitoring',
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
                expr: exprK8s %
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
                // Add support for multi-cluster monitoring.
                // The Kubernetes monitoring main dashboard may have a custom UID
                // (computed as an md5sum of its base ID and the cluster name) when the
                // cluster includes overrides/additional components such as apps.
                // At this point, the target cluster is unknown because the user’s
                // selection is not yet available.
                // The current implementation assumes that the first cluster defined in
                // values.yaml is the one to which the main Kubernetes dashboard should be linked.
                [{ title: 'Kubernetes Detail', url: '/d/%s?%s?var-cloud=$cloud' % [getUid($._config.grafanaDashboards.ids.k8sMonitoring, $._config.clusterMonitoring.clusters[0], $._config.templates.L1.k8s), $._config.grafanaDashboards.dataLinkCommonArgs] }]
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
            'OpenStack Kubernetes Monitoring',
            editable=$._config.grafanaDashboards.editable,
            graphTooltip=$._config.grafanaDashboards.tooltip,
            refresh=$._config.grafanaDashboards.refresh,
            time_from=$._config.grafanaDashboards.time_from,
            tags=$._config.grafanaDashboards.tags.openstack + $._config.grafanaDashboards.tags.k8sMonitoringMain,
            uid=$._config.grafanaDashboards.ids.openstackK8s,
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
            openStackStatPanel { gridPos: { x: 0, y: 1, w: 4, h: 3 } },
            k8sStatPanel { gridPos: { x: 4, y: 1, w: 4, h: 3 } },
          ]),
      } else {},
}
