/* OpenStack L2 dashboard - Control Plane health and certificates */
/* Feature flag ITUMonitoring has to be enabled to render this dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local statPanel = grafana.statPanel;
local template = grafana.template;
local table = grafana.tablePanel;
local prometheus = grafana.prometheus;

{
  grafanaDashboards+::

    if $.isITUMonitoring() then
      {
        'openstack-detail':
          local controlPlanePanel(service, metric) =
            /**
             * Create a Grafana Stat panel for a control-plane service.
             *
             * The panel visualizes a binary service state metric (0 = Down, 1 = Up),
             * and falls back to -1 (displaying "-") when the metric does not exist.
             *
             * @param service Display name of the control-plane component (panel title)
             * @param metric  Prometheus metric name used to check service status
             * @return A configured Grafana Stat panel object
             */
            statPanel.new(
              title=service,
              datasource='$datasource',
              unit='string',
              colorMode='background',
              graphMode='none',
              reducerFunction='lastNotNull',
            )
            .addThresholds([{ color: 'transparent', value: null }])
            .addMapping({
              type: 'value',
              options: {
                '0': { text: 'Down', color: $._config.grafanaDashboards.color.red },
                '1': { text: 'Up', color: $._config.grafanaDashboards.color.green },
                '-1': { text: '-' },
              },
            })
            .addTarget(
              prometheus.target(
                '%s{job=~"$job_openstack",instance=~"$cloud", cluster="$cluster"} OR on() vector(-1)' % metric
              )
            );

          local certificatesTable = table.new(
            title='Certificates',
            datasource='$datasource',
            sort={ col: 3 },
            styles=[
              // Hidden columns
              { pattern: 'Time', type: 'hidden' },
              { pattern: '__name__', type: 'hidden' },
              { pattern: 'cluster', type: 'hidden' },
              { pattern: 'pod', type: 'hidden' },
              { pattern: 'job', type: 'hidden' },
              { pattern: 'endpoint', type: 'hidden' },
              { pattern: 'namespace', type: 'hidden' },
              { pattern: 'prometheus', type: 'hidden' },
              { pattern: 'container', type: 'hidden' },
              { pattern: 'exported_namespace', type: 'hidden' },
              { pattern: 'prometheus_replica', type: 'hidden' },
              { pattern: 'service', type: 'hidden' },
              { pattern: 'serial_no', type: 'hidden' },
              // Table columns
              { alias: 'Common Name', pattern: 'cn', type: 'string' },
              { alias: 'Issuer Common Name', pattern: 'issuer_cn', type: 'string' },
              { alias: 'DNS Names', pattern: 'dnsnames', type: 'string' },
              { alias: 'Secret Name', pattern: 'secret', type: 'string' },
              { alias: 'Key', pattern: 'key', type: 'string' },
              {
                alias: 'TTL',
                pattern: 'Value',
                type: 'number',
                colors: [$._config.grafanaDashboards.color.red, $._config.grafanaDashboards.color.orange, $._config.grafanaDashboards.color.green],
                colorMode: 'cell',
                thresholds: [0, 8 * 24 * 60 * 60],
                unit: 's',
                decimals: 0,
              },
            ]
          )
                                    .addTarget(
            prometheus.target(
              format='table',
              instant=true,
              expr='ssl_kubernetes_cert_not_after{ job=~"$job_ssl", exported_namespace=~"$cloud_namespace", cluster="$cluster" } - time()'
            )
          );

          local openstackExporterJobTemplate =
            template.new(
              name='job_openstack',
              label='JobOpenStack',
              query='label_values(openstack_identity_up, job)',
              datasource='$datasource',
              sort=$._config.grafanaDashboards.templateSort,
              refresh=$._config.grafanaDashboards.templateRefresh,
              multi=false,
              includeAll=false,
            );

          local sslExporterJobTemplate =
            template.new(
              name='job_ssl',
              label='JobSSL',
              query='label_values(ssl_kubernetes_cert_not_after, job)',
              datasource='$datasource',
              sort=$._config.grafanaDashboards.templateSort,
              refresh=$._config.grafanaDashboards.templateRefresh,
              multi=false,
              includeAll=false,
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

          local cloudNamespace =
            template.new(
              name='cloud_namespace',
              label='Cloud Namespace',
              query='label_values(ssl_kubernetes_cert_not_after, exported_namespace)',
              datasource='$datasource',
              sort=$._config.grafanaDashboards.templateSort,
              refresh=$._config.grafanaDashboards.templateRefresh,
              multi=false,
              includeAll=false,
            );

          local panels = [
            // Control Plane section
            row.new('Control Plane') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
            // First row in CP section
            controlPlanePanel('Keystone', 'openstack_identity_up') { gridPos: { x: 0, y: 1, w: 3, h: 7 } },
            controlPlanePanel('Neutron', 'openstack_neutron_up') { gridPos: { x: 3, y: 1, w: 3, h: 7 } },
            controlPlanePanel('Nova', 'openstack_nova_up') { gridPos: { x: 6, y: 1, w: 3, h: 7 } },
            controlPlanePanel('Glance', 'openstack_glance_up') { gridPos: { x: 9, y: 1, w: 3, h: 7 } },
            controlPlanePanel('Cinder', 'openstack_cinder_up') { gridPos: { x: 12, y: 1, w: 3, h: 7 } },
            controlPlanePanel('Placement', 'openstack_placement_up') { gridPos: { x: 15, y: 1, w: 3, h: 7 } },
            controlPlanePanel('ObjectStore', 'openstack_object_store_up') { gridPos: { x: 18, y: 1, w: 3, h: 7 } },
            controlPlanePanel('LoadBalancer', 'openstack_loadbalancer_up') { gridPos: { x: 21, y: 1, w: 3, h: 7 } },
            // Second row in CP section
            controlPlanePanel('Gnocchi', 'openstack_gnocchi_up') { gridPos: { x: 0, y: 4, w: 3, h: 7 } },
            controlPlanePanel('Ironic', 'openstack_ironic_up') { gridPos: { x: 3, y: 4, w: 3, h: 7 } },
            controlPlanePanel('Designate', 'openstack_designate_up') { gridPos: { x: 6, y: 4, w: 3, h: 7 } },
            controlPlanePanel('Heat', 'openstack_heat_up') { gridPos: { x: 9, y: 4, w: 3, h: 7 } },
            controlPlanePanel('Trove', 'openstack_trove_up') { gridPos: { x: 12, y: 4, w: 3, h: 7 } },
            // Certificates section
            row.new('Certificates') { gridPos: { x: 0, y: 15, w: 24, h: 1 } },
            certificatesTable { tooltip+: { sort: 2 }, gridPos: { x: 0, y: 16, w: 24, h: 12 } },
          ];

          dashboard.new(
            'OpenStack Overview',
            editable=$._config.grafanaDashboards.editable,
            graphTooltip=$._config.grafanaDashboards.tooltip,
            refresh=$._config.grafanaDashboards.refresh,
            time_from=$._config.grafanaDashboards.time_from,
            tags=$._config.grafanaDashboards.tags.openstack,
            uid=$._config.grafanaDashboards.ids.openstackDetail,
          )
          .addTemplates([
            $.grafanaTemplates.datasourceTemplate(),
            $.grafanaTemplates.clusterTemplate('label_values(openstack_identity_up, cluster)'),
            openstackExporterJobTemplate,
            sslExporterJobTemplate,
            cloudTemplate,
            cloudNamespace,
          ])
          .addPanels(panels),
      } else {},
}
