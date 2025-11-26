local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;
local tablePanel = grafana.tablePanel;

{
  grafanaDashboards+:: {
    openstack: 
      local keystoneStatus =
        statPanel.new(
          title='Keystone status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

        .addMapping({
          type: 'value',
          options: {
            '0': { text: 'Down', color: $._config.grafanaDashboards.color.red },
            '1': { text: 'Up', color: $._config.grafanaDashboards.color.green },
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_identity_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local novaStatus =
        statPanel.new(
          title='Nova Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

        .addMapping({
          type: 'value',
          options: {
            '0': { text: 'Down', color: $._config.grafanaDashboards.color.red },
            '1': { text: 'Up', color: $._config.grafanaDashboards.color.green },
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_nova_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local neutronStatus =
        statPanel.new(
          title='Neutron Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

        .addMapping({
          type: 'value',
          options: {
            '0': { text: 'Down', color: $._config.grafanaDashboards.color.red },
            '1': { text: 'Up', color: $._config.grafanaDashboards.color.green },
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_neutron_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local cinderStatus =
        statPanel.new(
          title='Cinder Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

        .addMapping({
          type: 'value',
          options: {
            '0': { text: 'Down', color: $._config.grafanaDashboards.color.red },
            '1': { text: 'Up', color: $._config.grafanaDashboards.color.green },
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_cinder_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local glanceStatus =
        statPanel.new(
          title='Glance Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

        .addMapping({
          type: 'value',
          options: {
            '0': { text: 'Down', color: $._config.grafanaDashboards.color.red },
            '1': { text: 'Up', color: $._config.grafanaDashboards.color.green },
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_glance_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local placementStatus =
        statPanel.new(
          title='Placement Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

        .addMapping({
          type: 'value',
          options: {
            '0': { text: 'Down', color: $._config.grafanaDashboards.color.red },
            '1': { text: 'Up', color: $._config.grafanaDashboards.color.green },
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_placement_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local ironicStatus =
        statPanel.new(
          title='Ironic Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

        .addMapping({
          type: 'value',
          options: {
            '0': { text: 'Down', color: $._config.grafanaDashboards.color.red },
            '1': { text: 'Up', color: $._config.grafanaDashboards.color.green },
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_ironic_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local designateStatus =
        statPanel.new(
          title='Designate Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

        .addMapping({
          type: 'value',
          options: {
            '0': { text: 'Down', color: $._config.grafanaDashboards.color.red },
            '1': { text: 'Up', color: $._config.grafanaDashboards.color.green },
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_designate_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local loadbalancerStatus =
        statPanel.new(
          title='LoadBalancer Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

        .addMapping({
          type: 'value',
          options: {
            '0': { text: 'Down', color: $._config.grafanaDashboards.color.red },
            '1': { text: 'Up', color: $._config.grafanaDashboards.color.green },
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_loadbalancer_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local objectStoreStatus =
        statPanel.new(
          title='Object store Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

        .addMapping({
          type: 'value',
          options: {
            '0': { text: 'Down', color: $._config.grafanaDashboards.color.red },
            '1': { text: 'Up', color: $._config.grafanaDashboards.color.green },
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_object_store_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local containerInfraStatus =
        statPanel.new(
          title='Container infrastructure Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

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
            'openstack_container_infra_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)'
          )
        );

      local heatStatus =
        statPanel.new(
          title='Heat Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

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
            'openstack_heat_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local gnocchiStatus =
        statPanel.new(
          title='Gnocchi Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

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
            'openstack_gnocchi_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local troveStatus =
        statPanel.new(
          title='Trove Status',
          datasource='$datasource',
          unit='string',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
        ])

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
            'openstack_trove_up{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)')
        );

      local cpuUsagePanel =
        graphPanel.new(
          title='Overall CPU cores usage',
          datasource='$datasource',
          decimals=0,
          min=0,
          labelY1='cores',
        )

        .addTarget(
          prometheus.target(
            'sum by (instance) (openstack_placement_resource_usage{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="VCPU"})',
            legendFormat='{{instance}}-used-vcpu-cores',
          )
        )

        .addTarget(
          prometheus.target(
            'sum by (instance) (openstack_placement_resource_total{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="VCPU"})',
            legendFormat='{{instance}}-total-vcpu-cores',
          )
        );

      local overallMemoryUsagePanel =
        graphPanel.new(
          title='Overall memory usage (TiB)',
          datasource='$datasource',
          decimals=2,
          min=0,
          labelY1='Memory in TiB',
        )

        .addTarget(
          prometheus.target(
            'sum by (instance) (openstack_placement_resource_usage{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="MEMORY_MB"}) / 1024 / 1024',
            legendFormat='{{instance}}-memory-in-use',
          )
        )

        .addTarget(
          prometheus.target(
            'sum by (instance) (openstack_placement_resource_total{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="MEMORY_MB"}) / 1024 / 1024',
            legendFormat='{{instance}}-memory-available',
          )
        );

      local localStoragePanel =
        graphPanel.new(
          title='Local Storage (TB)',
          datasource='$datasource',
          decimals=2,
          min=0,
          labelY1='Local Storage (TB)',
        )

        .addTarget(
          prometheus.target(
            'sum by (instance) (openstack_placement_resource_usage{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="DISK_GB"}) / 1024',
            legendFormat='{{instance}}-local-storage-used',
          )
        )

        .addTarget(
          prometheus.target(
            'sum by (instance) (openstack_placement_resource_total{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="DISK_GB"}) / 1024',
            legendFormat='{{instance}}-local-storage-available',
          )
        );

      local groupsPanel =
        statPanel.new(
          title='Groups',
          datasource='$datasource',
          unit='none',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: $._config.grafanaDashboards.color.green, value: null },
          { color: $._config.grafanaDashboards.color.red, value: 80 },
        ])

        .addMapping({
          type: 'value',
          options: {
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target(
            'openstack_identity_groups{job=~"$job", instance=~"$instance", cluster=~"$cluster"} OR on() vector(-1)'
          )
        );

      local domainsPanel =
        statPanel.new(
          title='Domains',
          datasource='$datasource',
          unit='none',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: $._config.grafanaDashboards.color.green, value: null },
          { color: $._config.grafanaDashboards.color.red, value: 80 },
        ])

        .addMapping({
          type: 'value',
          options: {
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_identity_domains{job=~"$job", instance=~"$instance", cluster=~"$cluster"} OR on() vector(-1)')
        );

      local regionsPanel =
        statPanel.new(
          title='Regions',
          datasource='$datasource',
          unit='none',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: $._config.grafanaDashboards.color.green, value: null },
          { color: $._config.grafanaDashboards.color.red, value: 80 },
        ])

        .addMapping({
          type: 'value',
          options: {
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target('openstack_identity_regions{job=~"$job", instance=~"$instance", cluster=~"$cluster"} OR on() vector(-1)')
        );

      local projectsPanel =
        graphPanel.new(
          title='Projects',
          datasource='$datasource',
          decimals=0,
          min=0,
        )

        .addTarget(
          prometheus.target(
            'openstack_identity_projects{job=~"$job", instance=~"$instance", cluster=~"$cluster"}',
            legendFormat='{{instance}}-projects',
          )
        );

      local usersPanel =
        graphPanel.new(
          title='Users',
          datasource='$datasource',
          decimals=0,
          min=0,
        )

        .addTarget(
          prometheus.target(
            'openstack_identity_users{job=~"$job", instance=~"$instance", cluster=~"$cluster"}',
            legendFormat='{{instance}}-users',
          )
        );

      local projectDetailsPanel =
        tablePanel.new(
          title='Project details',
          description='Details for the projects in the OpenStack cloud.',
          datasource='$datasource',
          transform='timeseries_to_columns',
          sort={ col: 0, desc: false },

          styles=[
            {
              pattern: 'Value #B',
              alias: 'Enabled',
              type: 'string',
              mappingType: 1,
              colorMode: 'cell',

              valueMaps: [
                { value: 1, text: 'True' },
                { value: 2, text: 'False' },
              ],

              thresholds: [1, 2],

              colors: [
                $._config.grafanaDashboards.color.orange,
                $._config.grafanaDashboards.color.green,
                $._config.grafanaDashboards.color.red,
              ],
            },

            { pattern: 'name', alias: 'Name' },
            { pattern: 'id', alias: 'ID' },
            { pattern: 'instance', alias: 'Instance' },
            { pattern: 'domain_id', alias: 'Domain ID' },
            { pattern: 'is_domain', alias: 'Is domain' },
            { pattern: 'enabled', type: 'hidden' },
            { pattern: 'Value #A', type: 'hidden' },
            { pattern: 'job', type: 'hidden' },
            { pattern: '__name__', type: 'hidden' },
            { pattern: 'Time', type: 'hidden' },
            { pattern: 'cluster', type: 'hidden' },
            { pattern: 'container', type: 'hidden' },
            { pattern: 'endpoint', type: 'hidden' },
            { pattern: 'namespace', type: 'hidden' },
            { pattern: 'pod', type: 'hidden' },
            { pattern: 'prometheus', type: 'hidden' },
            { pattern: 'service', type: 'hidden' },
          ]
        )

        .addTarget(
          prometheus.target(
            'openstack_identity_project_info{job=~"$job", instance=~"$instance", cluster=~"$cluster"}',
            format='table',
            instant=true,
          )
        )

        .addTarget(
          prometheus.target(
            '(openstack_identity_project_info{job=~"$job",instance=~"$instance",cluster=~"$cluster",enabled="true"} * 1)\n       or\n       (openstack_identity_project_info{job=~"$job",instance=~"$instance",cluster=~"$cluster",enabled="false"} * 2)',
            format='table',
            instant=true,
            legendFormat='enabled_num'
          )
        )

        .addTransformation({
          id: 'merge',
          options: { reducers: [] },
        })

        .addTransformation({
          id: 'organize',
          options: {
            indexByName: {
              'Value #B': 0,
              name: 1,
              id: 2,
              instance: 3,
              domain_id: 4,
              is_domain: 5,
            },
          },
        });

      local novaAgentsUp =
        statPanel.new(
          title='Nova agents up',
          datasource='$datasource',
          unit='none',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
          { color: $._config.grafanaDashboards.color.orange, value: 0 },
          { color: $._config.grafanaDashboards.color.green, value: 1 },
        ])

        .addMapping({
          type: 'value',
          options: {
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target(
            'sum(openstack_nova_agent_state{job=~"$job", instance=~"$instance", adminState="enabled"}) OR on() vector(-1)')
        );

      local novaAgentsDown =
        statPanel.new(
          title='Nova agents down',
          datasource='$datasource',
          unit='none',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: $._config.grafanaDashboards.color.green, value: null },
          { color: $._config.grafanaDashboards.color.orange, value: 0.1 },
          { color: $._config.grafanaDashboards.color.red, value: 1 },
        ])

        .addMapping({
          type: 'value',
          options: {
            '-1': { text: '-' },
          },
        })

        .addTarget(
          prometheus.target(
            'count(openstack_nova_agent_state{job=~"$job", instance=~"$instance", adminState="enabled"})'
            + ' - sum(openstack_nova_agent_state{job=~"$job", instance=~"$instance", adminState="enabled"})'
            + ' OR on() vector(-1)')
        );

      local vmsPanel =
        graphPanel.new(
          title='VMs',
          datasource='$datasource',
          decimals=0,
          min=0,
          labelY1='VMs',
        )

        .addTarget(
          prometheus.target(
            'openstack_nova_total_vms{job=~"$job", instance=~"$instance", cluster=~"$cluster"}',
            legendFormat='{{instance}}-VMs',
          )
        );

      local vcpuUsagePanel =
        graphPanel.new(
          title='VCPU usage',
          datasource='$datasource',
          decimals=2,
          format='percentunit',
          min=0,
          max=1,
          labelY1='%',
        )

        .addTarget(
          prometheus.target(
            'openstack_nova_limits_vcpus_used{job=~"$job", instance=~"$instance", cluster=~"$cluster"} '
            + '/ clamp_min(openstack_nova_limits_vcpus_max{job=~"$job", instance=~"$instance", cluster=~"$cluster"}, 1)',
            legendFormat='{{instance}}-{{tenant}}',
          )
        );

      local memoryUsagePanel =
        graphPanel.new(
          title='Memory usage',
          datasource='$datasource',
          decimals=2,
          format='percentunit',
          min=0,
          max=1,
          labelY1='%',
        )

        .addTarget(
          prometheus.target(
            'openstack_nova_limits_memory_used{job=~"$job", instance=~"$instance", cluster=~"$cluster"} '
            + '/ clamp_min(openstack_nova_limits_memory_max{job=~"$job", instance=~"$instance", cluster=~"$cluster"}, 1)',
            legendFormat='{{instance}}-{{tenant}}',
          )
        );

      local instanceUsagePanel =
        graphPanel.new(
          title='Instance usage',
          datasource='$datasource',
          decimals=2,
          format='percentunit',
          min=0,
          max=1,
          labelY1='%',
        )

        .addTarget(
          prometheus.target(
            'openstack_nova_limits_instances_used{job=~"$job", instance=~"$instance", cluster=~"$cluster"} '
            + '/ clamp_min(openstack_nova_limits_instances_max{job=~"$job", instance=~"$instance", cluster=~"$cluster"}, 1)',
            legendFormat='{{instance}}-{{tenant}}',
          )
        );

      local novaAgentsStatusPanel =
        tablePanel.new(
          title='Agents status',
          datasource='$datasource',
          transform='timeseries_to_columns',
          sort={ col: 0, desc: false },

          styles=[
            {
              pattern: 'Value',
              alias: 'Status',
              type: 'string',
              colorMode: 'cell',
              mappingType: 1,

              valueMaps: [
                { text: 'Up', value: 1 },
                { text: 'Down', value: 0 },
              ],

              thresholds: [0, 0],
              colors: [
                $._config.grafanaDashboards.color.red,
                $._config.grafanaDashboards.color.orange,
                $._config.grafanaDashboards.color.green,
              ],
            },

            { pattern: 'job', type: 'hidden' },
            { pattern: '__name__', type: 'hidden' },
            { pattern: 'Time', type: 'hidden' },
            { pattern: 'cluster', type: 'hidden' },
            { pattern: 'container', type: 'hidden' },
            { pattern: 'endpoint', type: 'hidden' },
            { pattern: 'namespace', type: 'hidden' },
            { pattern: 'pod', type: 'hidden' },
            { pattern: 'prometheus', type: 'hidden' },
            { pattern: 'service', type: 'hidden' },
          ],
        )

        .addTarget(
          prometheus.target(
            'openstack_nova_agent_state{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            format='table',
            instant=true
          )
        )
        .addTransformation({
          id: 'organize',
          options: {
            indexByName: {
              Value: 0,
              adminState: 1,
              exported_service: 2,
              hostname: 3,
              id: 4,
              instance: 5,
              zone: 6,
            },
          },
        });

      local neutronAgentsUp =
        statPanel.new(
          title='Neutron agents up',
          datasource='$datasource',
          unit='none',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
          { color: $._config.grafanaDashboards.color.orange, value: 0 },
          { color: $._config.grafanaDashboards.color.green, value: 1 },
        ])

        .addMapping({
          type: 'value',
          options: {
            '-1': { text: '-', color: 'transparent' },
          },
        })

        .addTarget(
          prometheus.target(
            'sum(openstack_neutron_agent_state{job=~"$job",instance=~"$instance", adminState="up"}) OR on() vector(-1)',
            instant=true
          )
        );

      local neutronAgentsDown =
        statPanel.new(
          title='Neutron agents down',
          datasource='$datasource',
          unit='none',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: $._config.grafanaDashboards.color.green, value: null },
          { color: $._config.grafanaDashboards.color.orange, value: 0.1 },
          { color: $._config.grafanaDashboards.color.red, value: 1 },
        ])

        .addMapping({
          type: 'value',
          options: {
            '-1': { text: '-', color: 'transparent' },
          },
        })

        .addTarget(
          prometheus.target(
            'count(openstack_neutron_agent_state{job=~"$job",instance=~"$instance", adminState="up"}) - sum(openstack_neutron_agent_state{job=~"$job",instance=~"$instance", adminState="up"}) OR on() vector(-1)',
            instant=true
          )
        );

      local neutronNetworksPanel =
        graphPanel.new(
          title='Networks',
          datasource='$datasource',
          decimals=0,
          min=0,
        )

        .addTarget(
          prometheus.target(
            'openstack_neutron_networks{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            legendFormat='{{instance}}-networks'
          )
        );

      local neutronSubnetsPanel =
        graphPanel.new(
          title='Subnets',
          datasource='$datasource',
          decimals=0,
          min=0,
        )

        .addTarget(
          prometheus.target(
            'openstack_neutron_subnets{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            legendFormat='{{instance}}-subnets'
          )
        );

      local neutronRoutersPanel =
        graphPanel.new(
          title='Routers',
          datasource='$datasource',
          decimals=0,
          min=0,
        )

        .addTarget(
          prometheus.target(
            'openstack_neutron_routers{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            legendFormat='{{instance}}-routers-total'
          )
        )

        .addTarget(
          prometheus.target(
            'openstack_neutron_routers_not_active{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            legendFormat='{{instance}}-routers-inactive'
          )
        );

      local neutronPortsPanel =
        graphPanel.new(
          title='Ports',
          datasource='$datasource',
          decimals=0,
          min=0,
        )

        .addTarget(
          prometheus.target(
            'count by (instance) (openstack_neutron_port{job=~"$job",instance=~"$instance",cluster=~"$cluster"})',
            legendFormat='{{instance}}-ports-total'
          )
        )

        .addTarget(
          prometheus.target(
            'count by (instance)(openstack_neutron_port{status!="ACTIVE", job=~"$job",instance=~"$instance",cluster=~"$cluster"})',
            legendFormat='{{instance}}-ports-inactive'
          )
        )

        .addTarget(
          prometheus.target(
            'openstack_neutron_ports_no_ips{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            legendFormat='{{instance}}-ports-no-IPs'
          )
        );

      local neutronFloatingIPsPanel =
        graphPanel.new(
          title='Floating IPs',
          datasource='$datasource',
          decimals=0,
          min=0,
        )

        .addTarget(
          prometheus.target(
            'openstack_neutron_floating_ips{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            legendFormat='{{instance}}-IP-total'
          )
        )

        .addTarget(
          prometheus.target(
            'openstack_neutron_floating_ips_associated_not_active{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            legendFormat='{{instance}}-IPs-associated-inactive'
          )
        );

      local neutronIPsUsedBySubnetsPanel =
        graphPanel.new(
          title='IPs used by subnets',
          datasource='$datasource',
          description='The usage of available IP addresses broken down by subnets',
          decimals=1,
          min=0,
          max=1,
          format='percentunit',
        )

        .addTarget(
          prometheus.target(
            'sum by (job, instance, ip_version, subnet_name) (openstack_neutron_network_ip_availabilities_used{job=~"$job",instance=~"$instance",cluster=~"$cluster"}) / sum by (job, instance, ip_version, subnet_name)(openstack_neutron_network_ip_availabilities_total{job=~"$job",instance=~"$instance",cluster=~"$cluster"})',
            legendFormat='{{instance}}-{{subnet_name}}'
          )
        );

      local securityGroupsPanel =
        graphPanel.new(
          title='Security groups',
          datasource='$datasource',
          description='The number of Security groups managed by Neutron',
          decimals=0,
        )

        .addTarget(
          prometheus.target(
            'openstack_neutron_security_groups{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            legendFormat='{{instance}}-sec-groups'
          )
        );

      local routerDetailsPanel =
        tablePanel.new(
          title='Router details',
          description='Detailed view of the routers managed by Neutron',
          datasource='$datasource',
          transform='timeseries_to_columns',
          sort={ col: 0, desc: false },

          styles=[
            {
              pattern: 'Value #B',
              alias: 'Status',
              type: 'string',
              mappingType: 1,
              colorMode: 'cell',

              valueMaps: [
                { value: 1, text: 'ACTIVE' },
                { value: 2, text: 'DOWN' },
              ],

              thresholds: [1, 2],

              colors: [
                $._config.grafanaDashboards.color.orange,
                $._config.grafanaDashboards.color.green,
                $._config.grafanaDashboards.color.red,
              ],
            },

            { pattern: 'status', type: 'hidden' },
            { pattern: 'Value #A', type: 'hidden' },
            { pattern: 'job', type: 'hidden' },
            { pattern: '__name__', type: 'hidden' },
            { pattern: 'Time', type: 'hidden' },
            { pattern: 'cluster', type: 'hidden' },
            { pattern: 'container', type: 'hidden' },
            { pattern: 'endpoint', type: 'hidden' },
            { pattern: 'namespace', type: 'hidden' },
            { pattern: 'pod', type: 'hidden' },
            { pattern: 'prometheus', type: 'hidden' },
            { pattern: 'service', type: 'hidden' },
          ]
        )

        .addTarget(
          prometheus.target(
            'openstack_neutron_router{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            format='table',
            instant=true
          )
        )

        .addTarget(
          prometheus.target(
            '(openstack_neutron_router{job=~"$job",instance=~"$instance",cluster=~"$cluster",status="ACTIVE"} * 1)\n       or\n       (openstack_neutron_router{job=~"$job",instance=~"$instance",cluster=~"$cluster",status="DOWN"} * 2)',
            format='table',
            instant=true,
            legendFormat='status_num'
          )
        )

        .addTransformation({
          id: 'merge',
          options: { reducers: [] },
        })

        .addTransformation({
          id: 'organize',
          options: {
            indexByName: {
              'Value #B': 0,
              admin_state_up: 1,
              external_network_id: 2,
              id: 3,
              instance: 4,
              name: 5,
              project_id: 6,
            },
          },
        });

      local portDetailsPanel =
        tablePanel.new(
          title='Port details',
          description='Detailed view of the ports managed by Neutron',
          datasource='$datasource',
          transform='timeseries_to_columns',
          sort={ col: 0, desc: false },

          styles=[
            {
              pattern: 'Value #B',
              alias: 'Status',
              type: 'string',
              mappingType: 1,
              colorMode: 'cell',

              valueMaps: [
                { value: 1, text: 'ACTIVE' },
                { value: 2, text: 'DOWN' },
              ],

              thresholds: [1, 2],

              colors: [
                $._config.grafanaDashboards.color.orange,
                $._config.grafanaDashboards.color.green,
                $._config.grafanaDashboards.color.red,
              ],
            },

            { pattern: 'status', type: 'hidden' },
            { pattern: 'Value #A', type: 'hidden' },
            { pattern: 'job', type: 'hidden' },
            { pattern: '__name__', type: 'hidden' },
            { pattern: 'Time', type: 'hidden' },
            { pattern: 'cluster', type: 'hidden' },
            { pattern: 'container', type: 'hidden' },
            { pattern: 'endpoint', type: 'hidden' },
            { pattern: 'namespace', type: 'hidden' },
            { pattern: 'pod', type: 'hidden' },
            { pattern: 'prometheus', type: 'hidden' },
            { pattern: 'service', type: 'hidden' },
          ],
        )

        .addTarget(
          prometheus.target(
            'openstack_neutron_port{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            format='table',
            instant=true,
          )
        )

        .addTarget(
          prometheus.target(
            '(openstack_neutron_port{job=~"$job",instance=~"$instance",cluster=~"$cluster",status="ACTIVE"} * 1)\n     or\n     (openstack_neutron_port{job=~"$job",instance=~"$instance",cluster=~"$cluster",status="DOWN"} * 2)',
            format='table',
            instant=true,
            legendFormat='status_num'
          )
        )

        .addTransformation({
          id: 'merge',
          options: { reducers: [] },
        })

        .addTransformation({
          id: 'organize',
          options: {
            indexByName: {
              'Value #B': 0,
              admin_state_up: 1,
              'binding_vif_type ': 2,
              device_owner: 3,
              fixed_ips: 4,
              instance: 5,
              mac_address: 6,
              network_id: 7,
              uuid: 8,
            },
          },
        });

      local neutronAgentsStatusPanel =
        tablePanel.new(
          title='Agents status',
          datasource='$datasource',
          transform='timeseries_to_columns',
          sort={ col: 0, desc: false },

          styles=[
            {
              pattern: 'Value',
              alias: 'Status',
              type: 'string',
              colorMode: 'cell',
              mappingType: 1,

              valueMaps: [
                { text: 'Up', value: 1 },
                { text: 'Down', value: 0 },
              ],

              thresholds: [0, 0],
              colors: [
                $._config.grafanaDashboards.color.red,
                $._config.grafanaDashboards.color.orange,
                $._config.grafanaDashboards.color.green,
              ],
            },

            { pattern: 'job', type: 'hidden' },
            { pattern: '__name__', type: 'hidden' },
            { pattern: 'Time', type: 'hidden' },
            { pattern: 'cluster', type: 'hidden' },
            { pattern: 'container', type: 'hidden' },
            { pattern: 'endpoint', type: 'hidden' },
            { pattern: 'namespace', type: 'hidden' },
            { pattern: 'pod', type: 'hidden' },
            { pattern: 'prometheus', type: 'hidden' },
            { pattern: 'service', type: 'hidden' },
          ],
        )

        .addTarget(
          prometheus.target(
            'openstack_neutron_agent_state{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            format='table',
            instant=true,
          )
        )

        .addTransformation({
          id: 'organize',
          options: {
            indexByName: {
              Value: 0,
              adminState: 1,
              exported_service: 2,
              hostname: 3,
              id: 4,
              instance: 5,
              zone: 6,
            },
          },
        });

      local cinderAgentsUp =
        statPanel.new(
          title='Cinder agents up',
          datasource='$datasource',
          unit='none',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: 'transparent', value: null },
          { color: $._config.grafanaDashboards.color.orange, value: 0 },
          { color: $._config.grafanaDashboards.color.green, value: 1 },
        ])

        .addMapping({
          type: 'value',
          options: {
            '-1': { text: '-', color: 'transparent' },
          },
        })

        .addTarget(
          prometheus.target(
            'sum(openstack_cinder_agent_state{job=~"$job",instance=~"$instance", adminState="enabled"}) OR on() vector(-1)',
            instant=true,
          )
        );

      local cinderAgentsDown =
        statPanel.new(
          title='Cinder agents down',
          datasource='$datasource',
          unit='none',
          colorMode='background',
          graphMode='none',
          reducerFunction='lastNotNull',
        )

        .addThresholds([
          { color: $._config.grafanaDashboards.color.green, value: null },
          { color: $._config.grafanaDashboards.color.orange, value: 0.1 },
          { color: $._config.grafanaDashboards.color.red, value: 1 },
        ])

        .addMapping({
          type: 'value',
          options: {
            '-1': { text: '-', color: 'transparent' },
          },
        })

        .addTarget(
          prometheus.target(
            'count(openstack_cinder_agent_state{job=~"$job",instance=~"$instance", adminState="enabled"})'
            + '-sum(openstack_cinder_agent_state{job=~"$job",instance=~"$instance", adminState="enabled"})'
            + ' OR on() vector(-1)',
            instant=true,
          )
        );

      local volumesPanel =
        graphPanel.new(
          title='Volumes',
          datasource='$datasource',
          description='The number of volumes managed by Cinder',
          decimals=0,
        )
        .addTarget(
          prometheus.target(
            'openstack_cinder_volumes{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            legendFormat='{{instance}}-volumes'
          )
        );

      local volumeStatusPanel =
        graphPanel.new(
          title='Volume status',
          datasource='$datasource',
          description='The current status of volumes in Cinder',
          decimals=0,
        )

        .addTarget(
          prometheus.target(
            'openstack_cinder_volume_status_counter{job=~"$job",instance=~"$instance",status=~"error|error_backing-up|error_deleting|error_extending|error_restoring"} > 0',
            legendFormat='{{instance}}-{{status}}'
          )
        )

        .addTarget(
          prometheus.target(
            'openstack_cinder_volume_status_counter{job=~"$job",instance=~"$instance",status!~"error|error_backing-up|error_deleting|error_extending|error_restoring"} > 0',
            legendFormat='{{instance}}-{{status}}'
          )
        );

      local volumeUsagePanel =
        graphPanel.new(
          title='Volume usage',
          datasource='$datasource',
          description='The percent of volume storage in use for Cinder.',
          decimals=1,
          format='percentunit',
        )

        .addTarget(
          prometheus.target(
            'openstack_cinder_limits_volume_used_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"} / clamp_min(openstack_cinder_limits_volume_max_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"}, 1)',
            legendFormat='{{instance}}-{{tenant}}'
          )
        );

      local backupUsagePanel =
        graphPanel.new(
          title='Backup usage',
          datasource='$datasource',
          description='The percent of backup storage in use for Cinder.',
          decimals=1,
          format='percentunit',
        )

        .addTarget(
          prometheus.target(
            'openstack_cinder_limits_backup_used_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"} / clamp_min(openstack_cinder_limits_backup_max_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"}, 1)',
            legendFormat='{{instance}}-{{tenant}}'
          )
        );

      local poolUsagePanel =
        graphPanel.new(
          title='Pool usage',
          datasource='$datasource',
          description='The percent of pool capacity in use for Cinder',
          decimals=1,
          format='percentunit',
        )

        .addTarget(
          prometheus.target(
            '(openstack_cinder_pool_capacity_total_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"} - openstack_cinder_pool_capacity_free_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"}) / clamp_min(openstack_cinder_pool_capacity_total_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"}, 1)',
            legendFormat='{{instance}}-{{name}}'
          )
        );

      local snapshotsPanel =
        graphPanel.new(
          title='Snapshots',
          datasource='$datasource',
          description='The number of volume snapshots in Cinder',
          decimals=0,
          format='none',
        )

        .addTarget(
          prometheus.target(
            'openstack_cinder_snapshots{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            legendFormat='{{instance}}-snapshots'
          )
        );

      local cinderAgentsStatusPanel =
        tablePanel.new(
          title='Agents status',
          datasource='$datasource',
          transform='timeseries_to_columns',
          sort={ col: 0, desc: false },

          styles=[
            {
              pattern: 'Value',
              alias: 'Status',
              type: 'string',
              colorMode: 'cell',
              mappingType: 1,

              valueMaps: [
                { text: 'Up', value: 1 },
                { text: 'Down', value: 0 },
              ],

              thresholds: [0, 0],
              colors: [
                $._config.grafanaDashboards.color.red,
                $._config.grafanaDashboards.color.orange,
                $._config.grafanaDashboards.color.green,
              ],
            },

            { pattern: 'job', type: 'hidden' },
            { pattern: '__name__', type: 'hidden' },
            { pattern: 'Time', type: 'hidden' },
            { pattern: 'cluster', type: 'hidden' },
            { pattern: 'container', type: 'hidden' },
            { pattern: 'endpoint', type: 'hidden' },
            { pattern: 'namespace', type: 'hidden' },
            { pattern: 'pod', type: 'hidden' },
            { pattern: 'prometheus', type: 'hidden' },
            { pattern: 'service', type: 'hidden' },
          ],
        )

        .addTarget(
          prometheus.target(
            'openstack_cinder_agent_state{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            format='table',
            instant=true
          )
        )

        .addTransformation({
          id: 'organize',
          options: {
            indexByName: {
              Value: 0,
              adminState: 1,
              exported_service: 2,
              hostname: 3,
              instance: 4,
              uuid: 5,
              zone: 6,
            },
          },
        });

      local glanceImageCountPanel =
        graphPanel.new(
          title='Image count',
          datasource='$datasource',
          description='The number of images present in Glance',
          decimals=0,
        )

        .addTarget(
          prometheus.target(
            'openstack_glance_images{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            legendFormat='{{instance}}-images',
            interval='1m'
          )
        );

      local glanceImagesPanel =
        tablePanel.new(
          title='Images',
          datasource='$datasource',
          transform='timeseries_to_columns',
          sort={ col: 0, desc: false },

          styles=[
            { pattern: 'name', alias: 'Name' },
            { pattern: 'id', alias: 'ID' },
            { pattern: 'Value', alias: 'Size', type: 'number', unit: 'decbytes' },
            { pattern: 'instance', alias: 'Instance' },
            { pattern: 'tenant_id', alias: 'Tenant ID' },

            { pattern: 'cluster', type: 'hidden' },
            { pattern: 'container', type: 'hidden' },
            { pattern: 'endpoint', type: 'hidden' },
            { pattern: 'namespace', type: 'hidden' },
            { pattern: 'pod', type: 'hidden' },
            { pattern: 'prometheus', type: 'hidden' },
            { pattern: 'service', type: 'hidden' },
            { pattern: 'job', type: 'hidden' },
            { pattern: '__name__', type: 'hidden' },
            { pattern: 'Time', type: 'hidden' },
          ]
        )

        .addTarget(
          prometheus.target(
            'openstack_glance_image_bytes{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
            format='table',
            instant=true
          )
        )

        .addTransformation({
          id: 'joinByField',
          options: {
            byField: 'Time',
            mode: 'outer',
          },
        })

        .addTransformation({
          id: 'organize',
          options: {
            indexByName: {
              name: 0,
              id: 1,
              Value: 2,
              instance: 3,
              tenant_id: 4,
            },
          },
        });

      local panels = [
        row.new('Service Status') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        keystoneStatus { gridPos: { x: 0, y: 1, w: 3, h: 3 } },
        novaStatus { gridPos: { x: 3, y: 1, w: 3, h: 3 } },
        neutronStatus { gridPos: { x: 6, y: 1, w: 3, h: 3 } },
        cinderStatus { gridPos: { x: 9, y: 1, w: 3, h: 3 } },
        glanceStatus { gridPos: { x: 12, y: 1, w: 3, h: 3 } },
        placementStatus { gridPos: { x: 15, y: 1, w: 3, h: 3 } },
        ironicStatus { gridPos: { x: 18, y: 1, w: 3, h: 3 } },
        designateStatus { gridPos: { x: 21, y: 1, w: 3, h: 3 } },
        loadbalancerStatus { gridPos: { x: 0, y: 4, w: 3, h: 3 } },
        objectStoreStatus { gridPos: { x: 3, y: 4, w: 3, h: 3 } },
        containerInfraStatus { gridPos: { x: 6, y: 4, w: 3, h: 3 } },
        heatStatus { gridPos: { x: 9, y: 4, w: 3, h: 3 } },
        gnocchiStatus { gridPos: { x: 12, y: 4, w: 3, h: 3 } },
        troveStatus { gridPos: { x: 15, y: 4, w: 3, h: 3 } },

        row.new('Resource Usage') { gridPos: { x: 0, y: 5, w: 24, h: 1 } },
        cpuUsagePanel { gridPos: { x: 0, y: 5, w: 8, h: 8 } },
        overallMemoryUsagePanel { gridPos: { x: 8, y: 5, w: 8, h: 8 } },
        localStoragePanel { gridPos: { x: 16, y: 5, w: 8, h: 8 } },

        row.new('Keystone') { gridPos: { x: 0, y: 6, w: 24, h: 1 } },
        keystoneStatus { gridPos: { x: 0, y: 7, w: 3, h: 3 } },
        groupsPanel { gridPos: { x: 0, y: 10, w: 3, h: 3 } },
        domainsPanel { gridPos: { x: 0, y: 13, w: 3, h: 3 } },
        regionsPanel { gridPos: { x: 0, y: 16, w: 3, h: 3 } },
        projectsPanel { gridPos: { x: 3, y: 7, w: 21, h: 6 } },
        usersPanel { gridPos: { x: 3, y: 13, w: 21, h: 6 } },
        projectDetailsPanel { gridPos: { x: 0, y: 20, w: 24, h: 12 } },

        row.new('Nova') { gridPos: { x: 0, y: 21, w: 24, h: 1 } },
        novaStatus { gridPos: { x: 0, y: 22, w: 3, h: 5 } },
        novaAgentsUp { gridPos: { x: 0, y: 27, w: 3, h: 5 } },
        novaAgentsDown { gridPos: { x: 0, y: 32, w: 3, h: 5 } },
        vmsPanel { gridPos: { x: 3, y: 22, w: 10.5, h: 7.5 } },
        vcpuUsagePanel { gridPos: { x: 13.5, y: 22, w: 10.5, h: 7.5 } },
        memoryUsagePanel { gridPos: { x: 3, y: 29.5, w: 10.5, h: 7.5 } },
        instanceUsagePanel { gridPos: { x: 13.5, y: 29.5, w: 10.5, h: 7.5 } },
        novaAgentsStatusPanel { gridPos: { x: 0, y: 37, w: 24, h: 8 } },

        row.new('Neutron') { gridPos: { x: 0, y: 45, w: 24, h: 1 } },
        neutronStatus { gridPos: { x: 0, y: 46, w: 3, h: 5 } },
        neutronAgentsUp { gridPos: { x: 0, y: 51, w: 3, h: 5 } },
        neutronAgentsDown { gridPos: { x: 0, y: 56, w: 3, h: 5 } },
        neutronNetworksPanel { gridPos: { x: 3, y: 46, w: 10.5, h: 10 } },
        neutronSubnetsPanel { gridPos: { x: 13.5, y: 46, w: 10.5, h: 10 } },
        neutronRoutersPanel { gridPos: { x: 3, y: 56, w: 10.5, h: 10 } },
        neutronPortsPanel { gridPos: { x: 13.5, y: 56, w: 10.5, h: 10 } },
        neutronFloatingIPsPanel { gridPos: { x: 3, y: 66, w: 10.5, h: 10 } },
        neutronIPsUsedBySubnetsPanel { gridPos: { x: 13.5, y: 56, w: 10.5, h: 10 } },
        securityGroupsPanel { gridPos: { x: 3, y: 66, w: 10.5, h: 10 } },
        routerDetailsPanel { gridPos: { x: 0, y: 76, w: 24, h: 10 } },
        portDetailsPanel { gridPos: { x: 0, y: 86, w: 24, h: 10 } },
        neutronAgentsStatusPanel { gridPos: { x: 0, y: 96, w: 24, h: 10 } },

        row.new('Cinder') { gridPos: { x: 0, y: 106, w: 24, h: 1 } },
        cinderStatus { gridPos: { x: 0, y: 107, w: 3, h: 5 } },
        cinderAgentsUp { gridPos: { x: 0, y: 112, w: 3, h: 5 } },
        cinderAgentsDown { gridPos: { x: 0, y: 117, w: 3, h: 5 } },
        volumesPanel { gridPos: { x: 3, y: 107, w: 10.5, h: 8 } },
        volumeStatusPanel { gridPos: { x: 13.5, y: 107, w: 10.5, h: 8 } },
        volumeUsagePanel { gridPos: { x: 3, y: 115, w: 10.5, h: 8 } },
        backupUsagePanel { gridPos: { x: 13.5, y: 115, w: 10.5, h: 8 } },
        poolUsagePanel { gridPos: { x: 3, y: 123, w: 10.5, h: 8 } },
        snapshotsPanel { gridPos: { x: 13.5, y: 123, w: 10.5, h: 8 } },
        cinderAgentsStatusPanel { gridPos: { x: 0, y: 131, w: 24, h: 10 } },

        row.new('Glance') { gridPos: { x: 0, y: 141, w: 24, h: 1 } },
        glanceStatus { gridPos: { x: 0, y: 142, w: 3, h: 8 } },
        glanceImageCountPanel { gridPos: { x: 3, y: 142, w: 21, h: 8 } },
        glanceImagesPanel { gridPos: { x: 0, y: 150, w: 24, h: 10 } },

      ];

      dashboard.new(
        'OpenStack Overview App',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sApps,
        uid=$._config.grafanaDashboards.ids.openstack,
      )

      .addTemplates([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(openstack_identity_up, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(openstack_identity_up{cluster="$cluster"},job)'),
        $.grafanaTemplates.instanceTemplate('label_values(openstack_identity_up{cluster="$cluster"},instance)'),
      ])

      .addPanels(panels)
     },
}
