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

/* K8s openstack dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local timeSeriesPanel = grafana.panel.timeSeries;
local statPanel = grafana.panel.stat;
local table = grafana.panel.table;
local fieldOverride = grafana.panel.table.fieldOverride;
local row = grafana.panel.row;
local prometheus = grafana.query.prometheus;

{
  grafanaDashboards+:: {
    openstack:
      local color = $._config.grafanaDashboards.color;

      local promTarget(expr, legendFormat=null, instant=false, interval=null) =
        prometheus.withExpr(expr)
        + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {})
        + (if instant then prometheus.withInstant(true) else {})
        + (if interval != null then prometheus.withInterval(interval) else {});

      local tableTarget(expr, legendFormat=null) =
        prometheus.withExpr(expr) + prometheus.withFormat('table') + prometheus.withInstant(true)
        + (if legendFormat != null then prometheus.withLegendFormat(legendFormat) else {});

      local statBase(title, expr, steps, mapOptions, unit='none', instant=false) =
        statPanel.new(title)
        + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + statPanel.standardOptions.withUnit(unit)
        + statPanel.options.withColorMode('background')
        + statPanel.options.withGraphMode('none')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps(steps)
        + statPanel.standardOptions.withMappings([{ type: 'value', options: mapOptions }])
        + statPanel.queryOptions.withTargets([promTarget(expr, instant=instant)]);

      local statusPanel(name, metric) =
        statBase(name + ' status',
                 '%s{job=~"$job",instance=~"$instance", cluster="$cluster"} OR on() vector(-1)' % metric,
                 [{ color: 'transparent', value: null }],
                 { '0': { text: 'Down', color: color.red }, '1': { text: 'Up', color: color.green }, '-1': { text: '-' } },
                 unit='string');

      local timeSeriesBase(title, targets, labelY1=null, unit=null, decimals=null, min=null, max=null, desc=null) =
        timeSeriesPanel.new(title)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', '$datasource')
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + (if labelY1 != null then timeSeriesPanel.fieldConfig.defaults.custom.withAxisLabel(labelY1) else {})
        + (if unit != null then timeSeriesPanel.standardOptions.withUnit(unit) else {})
        + (if decimals != null then timeSeriesPanel.standardOptions.withDecimals(decimals) else {})
        + (if min != null then timeSeriesPanel.standardOptions.withMin(min) else {})
        + (if max != null then timeSeriesPanel.standardOptions.withMax(max) else {})
        + (if desc != null then timeSeriesPanel.panelOptions.withDescription(desc) else {})
        + timeSeriesPanel.queryOptions.withTargets(targets);

      local commonHidden = ['job', '__name__', 'Time', 'cluster', 'container', 'endpoint', 'namespace', 'pod', 'prometheus', 'service'];

      local hide(name) =
        fieldOverride.byName.new(name)
        + fieldOverride.byName.withProperty('custom.hidden', true);

      local rename(name, disp) =
        fieldOverride.byName.new(name)
        + fieldOverride.byName.withProperty('displayName', disp);

      local statusCol(name, disp, mapOptions, steps, width) =
        fieldOverride.byName.new(name)
        + fieldOverride.byName.withProperty('displayName', disp)
        + fieldOverride.byName.withProperty('mappings', [{ type: 'value', options: mapOptions }])
        + fieldOverride.byName.withProperty('custom.cellOptions', { type: 'color-background' })
        + fieldOverride.byName.withProperty('thresholds', { mode: 'absolute', steps: steps })
        + fieldOverride.byName.withProperty('custom.width', width);

      local tableBase(title, desc, overrides, transformations, targets) =
        table.new(title)
        + table.queryOptions.withDatasource('prometheus', '$datasource')
        + (if desc != null then timeSeriesPanel.panelOptions.withDescription(desc) else {})
        + table.standardOptions.withOverrides([hide(n) for n in commonHidden] + overrides)
        + table.queryOptions.withTransformations(transformations)
        + table.queryOptions.withTargets(targets);

      local enabledMap = { '1': { text: 'True' }, '2': { text: 'False' } };
      local activeMap = { '1': { text: 'ACTIVE' }, '2': { text: 'DOWN' } };
      local detailSteps = [{ color: color.orange, value: null }, { color: color.green, value: 1 }, { color: color.red, value: 2 }];
      local agentMap = { '1': { text: 'Up' }, '0': { text: 'Down' } };
      local agentSteps = [{ color: color.red, value: null }, { color: color.orange, value: 0 }, { color: color.green, value: 1 }];

      local cpuUsagePanel = timeSeriesBase('Overall CPU cores usage', [
        promTarget('sum by (instance) (openstack_placement_resource_usage{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="VCPU"})', '{{instance}}-used-vcpu-cores'),
        promTarget('sum by (instance) (openstack_placement_resource_total{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="VCPU"})', '{{instance}}-total-vcpu-cores'),
      ], labelY1='cores', decimals=0, min=0);

      local overallMemoryUsagePanel = timeSeriesBase('Overall memory usage (TiB)', [
        promTarget('sum by (instance) (openstack_placement_resource_usage{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="MEMORY_MB"}) / 1024 / 1024', '{{instance}}-memory-in-use'),
        promTarget('sum by (instance) (openstack_placement_resource_total{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="MEMORY_MB"}) / 1024 / 1024', '{{instance}}-memory-available'),
      ], labelY1='Memory in TiB', decimals=2, min=0);

      local localStoragePanel = timeSeriesBase('Local Storage (TB)', [
        promTarget('sum by (instance) (openstack_placement_resource_usage{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="DISK_GB"}) / 1024', '{{instance}}-local-storage-used'),
        promTarget('sum by (instance) (openstack_placement_resource_total{job=~"$job", instance=~"$instance", cluster=~"$cluster", resourcetype="DISK_GB"}) / 1024', '{{instance}}-local-storage-available'),
      ], labelY1='Local Storage (TB)', decimals=2, min=0);

      local idSteps = [{ color: color.green, value: null }, { color: color.red, value: 80 }];
      local groupsPanel = statBase('Groups', 'openstack_identity_groups{job=~"$job", instance=~"$instance", cluster=~"$cluster"} OR on() vector(-1)', idSteps, { '-1': { text: '-' } });
      local domainsPanel = statBase('Domains', 'openstack_identity_domains{job=~"$job", instance=~"$instance", cluster=~"$cluster"} OR on() vector(-1)', idSteps, { '-1': { text: '-' } });
      local regionsPanel = statBase('Regions', 'openstack_identity_regions{job=~"$job", instance=~"$instance", cluster=~"$cluster"} OR on() vector(-1)', idSteps, { '-1': { text: '-' } });
      local projectsPanel = timeSeriesBase('Projects', [promTarget('openstack_identity_projects{job=~"$job", instance=~"$instance", cluster=~"$cluster"}', '{{instance}}-projects')], decimals=0, min=0);
      local usersPanel = timeSeriesBase('Users', [promTarget('openstack_identity_users{job=~"$job", instance=~"$instance", cluster=~"$cluster"}', '{{instance}}-users')], decimals=0, min=0);

      local projectDetailsPanel = tableBase('Project details',
                                            'Details for the projects in the OpenStack cloud.',
                                            [
                                              hide('enabled'),
                                              hide('Value #A'),
                                              statusCol('Value #B', 'Enabled', enabledMap, detailSteps, 113),
                                              rename('name', 'Name'),
                                              rename('id', 'ID'),
                                              rename('instance', 'Instance'),
                                              rename('domain_id', 'Domain ID'),
                                              rename('is_domain', 'Is domain'),
                                            ],
                                            [{ id: 'merge', options: { reducers: [] } }, { id: 'organize', options: { indexByName: { 'Value #B': 0, name: 1, id: 2, instance: 3, domain_id: 4, is_domain: 5 } } }],
                                            [
                                              tableTarget('openstack_identity_project_info{job=~"$job", instance=~"$instance", cluster=~"$cluster"}'),
                                              tableTarget('(openstack_identity_project_info{job=~"$job",instance=~"$instance",cluster=~"$cluster",enabled="true"} * 1)\n       or\n       (openstack_identity_project_info{job=~"$job",instance=~"$instance",cluster=~"$cluster",enabled="false"} * 2)', 'enabled_num'),
                                            ]);

      local novaAgentsUp = statBase('Nova agents up',
                                    'sum(openstack_nova_agent_state{job=~"$job", instance=~"$instance", adminState="enabled"}) OR on() vector(-1)',
                                    [{ color: 'transparent', value: null }, { color: color.orange, value: 0 }, { color: color.green, value: 1 }],
                                    { '-1': { text: '-' } });

      local novaAgentsDown = statBase('Nova agents down',
                                      'count(openstack_nova_agent_state{job=~"$job", instance=~"$instance", adminState="enabled"}) - sum(openstack_nova_agent_state{job=~"$job", instance=~"$instance", adminState="enabled"}) OR on() vector(-1)',
                                      [{ color: color.green, value: null }, { color: color.orange, value: 0.1 }, { color: color.red, value: 1 }],
                                      { '-1': { text: '-' } });

      local vmsPanel = timeSeriesBase('VMs', [promTarget('openstack_nova_total_vms{job=~"$job", instance=~"$instance", cluster=~"$cluster"}', '{{instance}}-VMs')], labelY1='VMs', decimals=0, min=0);
      local vcpuUsagePanel = timeSeriesBase('VCPU usage', [promTarget('openstack_nova_limits_vcpus_used{job=~"$job", instance=~"$instance", cluster=~"$cluster"} / clamp_min(openstack_nova_limits_vcpus_max{job=~"$job", instance=~"$instance", cluster=~"$cluster"}, 1)', '{{instance}}-{{tenant}}')], labelY1='%', unit='percentunit', decimals=2, min=0, max=1);
      local memoryUsagePanel = timeSeriesBase('Memory usage', [promTarget('openstack_nova_limits_memory_used{job=~"$job", instance=~"$instance", cluster=~"$cluster"} / clamp_min(openstack_nova_limits_memory_max{job=~"$job", instance=~"$instance", cluster=~"$cluster"}, 1)', '{{instance}}-{{tenant}}')], labelY1='%', unit='percentunit', decimals=2, min=0, max=1);
      local instanceUsagePanel = timeSeriesBase('Instance usage', [promTarget('openstack_nova_limits_instances_used{job=~"$job", instance=~"$instance", cluster=~"$cluster"} / clamp_min(openstack_nova_limits_instances_max{job=~"$job", instance=~"$instance", cluster=~"$cluster"}, 1)', '{{instance}}-{{tenant}}')], labelY1='%', unit='percentunit', decimals=2, min=0, max=1);

      local agentsStatusTbl(title, expr, indexByName) =
        tableBase(title,
                  null,
                  [statusCol('Value', 'Status', agentMap, agentSteps, 104)],
                  [{ id: 'organize', options: { indexByName: indexByName } }],
                  [tableTarget(expr)]);

      local novaAgentsStatusPanel = agentsStatusTbl('Agents status',
                                                    'openstack_nova_agent_state{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
                                                    { Value: 0, adminState: 1, exported_service: 2, hostname: 3, id: 4, instance: 5, zone: 6 });

      local neutronAgentsUp = statBase('Neutron agents up',
                                       'sum(openstack_neutron_agent_state{job=~"$job",instance=~"$instance", adminState="up"}) OR on() vector(-1)',
                                       [{ color: 'transparent', value: null }, { color: color.orange, value: 0 }, { color: color.green, value: 1 }],
                                       { '-1': { text: '-', color: 'transparent' } },
                                       instant=true);

      local neutronAgentsDown = statBase('Neutron agents down',
                                         'count(openstack_neutron_agent_state{job=~"$job",instance=~"$instance", adminState="up"}) - sum(openstack_neutron_agent_state{job=~"$job",instance=~"$instance", adminState="up"}) OR on() vector(-1)',
                                         [{ color: color.green, value: null }, { color: color.orange, value: 0.1 }, { color: color.red, value: 1 }],
                                         { '-1': { text: '-', color: 'transparent' } },
                                         instant=true);

      local neutronNetworksPanel = timeSeriesBase('Networks', [promTarget('openstack_neutron_networks{job=~"$job",instance=~"$instance",cluster=~"$cluster"}', '{{instance}}-networks')], decimals=0, min=0);
      local neutronSubnetsPanel = timeSeriesBase('Subnets', [promTarget('openstack_neutron_subnets{job=~"$job",instance=~"$instance",cluster=~"$cluster"}', '{{instance}}-subnets')], decimals=0, min=0);

      local neutronRoutersPanel = timeSeriesBase('Routers', [
        promTarget('openstack_neutron_routers{job=~"$job",instance=~"$instance",cluster=~"$cluster"}', '{{instance}}-routers-total'),
        promTarget('openstack_neutron_routers_not_active{job=~"$job",instance=~"$instance",cluster=~"$cluster"}', '{{instance}}-routers-inactive'),
      ], decimals=0, min=0);

      local neutronPortsPanel = timeSeriesBase('Ports', [
        promTarget('count by (instance) (openstack_neutron_port{job=~"$job",instance=~"$instance",cluster=~"$cluster"})', '{{instance}}-ports-total'),
        promTarget('count by (instance)(openstack_neutron_port{status!="ACTIVE", job=~"$job",instance=~"$instance",cluster=~"$cluster"})', '{{instance}}-ports-inactive'),
        promTarget('openstack_neutron_ports_no_ips{job=~"$job",instance=~"$instance",cluster=~"$cluster"}', '{{instance}}-ports-no-IPs'),
      ], decimals=0, min=0);

      local neutronFloatingIPsPanel = timeSeriesBase('Floating IPs', [
        promTarget('openstack_neutron_floating_ips{job=~"$job",instance=~"$instance",cluster=~"$cluster"}', '{{instance}}-IP-total'),
        promTarget('openstack_neutron_floating_ips_associated_not_active{job=~"$job",instance=~"$instance",cluster=~"$cluster"}', '{{instance}}-IPs-associated-inactive'),
      ], decimals=0, min=0);

      local neutronIPsUsedBySubnetsPanel = timeSeriesBase('IPs used by subnets', [promTarget('sum by (job, instance, ip_version, subnet_name) (openstack_neutron_network_ip_availabilities_used{job=~"$job",instance=~"$instance",cluster=~"$cluster"}) / sum by (job, instance, ip_version, subnet_name)(openstack_neutron_network_ip_availabilities_total{job=~"$job",instance=~"$instance",cluster=~"$cluster"})', '{{instance}}-{{subnet_name}}')], unit='percentunit', decimals=1, min=0, max=1, desc='The usage of available IP addresses broken down by subnets');
      local securityGroupsPanel = timeSeriesBase('Security groups', [promTarget('openstack_neutron_security_groups{job=~"$job",instance=~"$instance",cluster=~"$cluster"}', '{{instance}}-sec-groups')], decimals=0, desc='The number of Security groups managed by Neutron');

      local routerDetailsPanel = tableBase('Router details',
                                           'Detailed view of the routers managed by Neutron',
                                           [hide('status'), hide('Value #A'), statusCol('Value #B', 'Status', activeMap, detailSteps, 104)],
                                           [{ id: 'merge', options: { reducers: [] } }, { id: 'organize', options: { indexByName: { 'Value #B': 0, admin_state_up: 1, external_network_id: 2, id: 3, instance: 4, name: 5, project_id: 6 } } }],
                                           [
                                             tableTarget('openstack_neutron_router{job=~"$job",instance=~"$instance",cluster=~"$cluster"}'),
                                             tableTarget('(openstack_neutron_router{job=~"$job",instance=~"$instance",cluster=~"$cluster",status="ACTIVE"} * 1)\n       or\n       (openstack_neutron_router{job=~"$job",instance=~"$instance",cluster=~"$cluster",status="DOWN"} * 2)', 'status_num'),
                                           ]);

      local portDetailsPanel = tableBase('Port details',
                                         'Detailed view of the ports managed by Neutron',
                                         [hide('status'), hide('Value #A'), statusCol('Value #B', 'Status', activeMap, detailSteps, 104)],
                                         [{ id: 'merge', options: { reducers: [] } }, { id: 'organize', options: { indexByName: { 'Value #B': 0, admin_state_up: 1, 'binding_vif_type ': 2, device_owner: 3, fixed_ips: 4, instance: 5, mac_address: 6, network_id: 7, uuid: 8 } } }],
                                         [
                                           tableTarget('openstack_neutron_port{job=~"$job",instance=~"$instance",cluster=~"$cluster"}'),
                                           tableTarget('(openstack_neutron_port{job=~"$job",instance=~"$instance",cluster=~"$cluster",status="ACTIVE"} * 1)\n     or\n     (openstack_neutron_port{job=~"$job",instance=~"$instance",cluster=~"$cluster",status="DOWN"} * 2)', 'status_num'),
                                         ]);

      local neutronAgentsStatusPanel = agentsStatusTbl('Agents status',
                                                       'openstack_neutron_agent_state{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
                                                       { Value: 0, adminState: 1, exported_service: 2, hostname: 3, id: 4, instance: 5, zone: 6 });

      local cinderAgentsUp = statBase('Cinder agents up',
                                      'sum(openstack_cinder_agent_state{job=~"$job",instance=~"$instance", adminState="enabled"}) OR on() vector(-1)',
                                      [{ color: 'transparent', value: null }, { color: color.orange, value: 0 }, { color: color.green, value: 1 }],
                                      { '-1': { text: '-', color: 'transparent' } },
                                      instant=true);

      local cinderAgentsDown = statBase('Cinder agents down',
                                        'count(openstack_cinder_agent_state{job=~"$job",instance=~"$instance", adminState="enabled"})-sum(openstack_cinder_agent_state{job=~"$job",instance=~"$instance", adminState="enabled"}) OR on() vector(-1)',
                                        [{ color: color.green, value: null }, { color: color.orange, value: 0.1 }, { color: color.red, value: 1 }],
                                        { '-1': { text: '-', color: 'transparent' } },
                                        instant=true);

      local volumesPanel = timeSeriesBase('Volumes', [promTarget('openstack_cinder_volumes{job=~"$job",instance=~"$instance",cluster=~"$cluster"}', '{{instance}}-volumes')], decimals=0, desc='The number of volumes managed by Cinder');

      local volumeStatusPanel = timeSeriesBase('Volume status', [
        promTarget('openstack_cinder_volume_status_counter{job=~"$job",instance=~"$instance",status=~"error|error_backing-up|error_deleting|error_extending|error_restoring"} > 0', '{{instance}}-{{status}}'),
        promTarget('openstack_cinder_volume_status_counter{job=~"$job",instance=~"$instance",status!~"error|error_backing-up|error_deleting|error_extending|error_restoring"} > 0', '{{instance}}-{{status}}'),
      ], decimals=0, desc='The current status of volumes in Cinder');

      local volumeUsagePanel = timeSeriesBase('Volume usage', [promTarget('openstack_cinder_limits_volume_used_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"} / clamp_min(openstack_cinder_limits_volume_max_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"}, 1)', '{{instance}}-{{tenant}}')], unit='percentunit', decimals=1, desc='The percent of volume storage in use for Cinder.');
      local backupUsagePanel = timeSeriesBase('Backup usage', [promTarget('openstack_cinder_limits_backup_used_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"} / clamp_min(openstack_cinder_limits_backup_max_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"}, 1)', '{{instance}}-{{tenant}}')], unit='percentunit', decimals=1, desc='The percent of backup storage in use for Cinder.');
      local poolUsagePanel = timeSeriesBase('Pool usage', [promTarget('(openstack_cinder_pool_capacity_total_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"} - openstack_cinder_pool_capacity_free_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"}) / clamp_min(openstack_cinder_pool_capacity_total_gb{job=~"$job",instance=~"$instance",cluster=~"$cluster"}, 1)', '{{instance}}-{{name}}')], unit='percentunit', decimals=1, desc='The percent of pool capacity in use for Cinder');
      local snapshotsPanel = timeSeriesBase('Snapshots', [promTarget('openstack_cinder_snapshots{job=~"$job",instance=~"$instance",cluster=~"$cluster"}', '{{instance}}-snapshots')], unit='none', decimals=0, desc='The number of volume snapshots in Cinder');

      local cinderAgentsStatusPanel = agentsStatusTbl('Agents status',
                                                      'openstack_cinder_agent_state{job=~"$job",instance=~"$instance",cluster=~"$cluster"}',
                                                      { Value: 0, adminState: 1, exported_service: 2, hostname: 3, instance: 4, uuid: 5, zone: 6 });

      local glanceImageCountPanel = timeSeriesBase('Image count', [promTarget('openstack_glance_images{job=~"$job",instance=~"$instance",cluster=~"$cluster"}', '{{instance}}-images', interval='1m')], decimals=0, desc='The number of images present in Glance');

      local glanceImagesPanel = tableBase('Images',
                                          null,
                                          [
                                            rename('name', 'Name'),
                                            rename('id', 'ID'),
                                            fieldOverride.byName.new('Value')
                                            + fieldOverride.byName.withProperty('displayName', 'Size')
                                            + fieldOverride.byName.withProperty('unit', 'decbytes')
                                            + fieldOverride.byName.withProperty('custom.width', 86),
                                            rename('instance', 'Instance'),
                                            rename('tenant_id', 'Tenant ID'),
                                          ],
                                          [{ id: 'joinByField', options: { byField: 'Time', mode: 'outer' } }, { id: 'organize', options: { indexByName: { name: 0, id: 1, Value: 2, instance: 3, tenant_id: 4 } } }],
                                          [tableTarget('openstack_glance_image_bytes{job=~"$job",instance=~"$instance",cluster=~"$cluster"}')]);

      local panels = [
        row.new('Service Status') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
        statusPanel('Keystone', 'openstack_identity_up') + { gridPos: { x: 0, y: 1, w: 3, h: 3 } },
        statusPanel('Nova', 'openstack_nova_up') + { gridPos: { x: 3, y: 1, w: 3, h: 3 } },
        statusPanel('Neutron', 'openstack_neutron_up') + { gridPos: { x: 6, y: 1, w: 3, h: 3 } },
        statusPanel('Cinder', 'openstack_cinder_up') + { gridPos: { x: 9, y: 1, w: 3, h: 3 } },
        statusPanel('Glance', 'openstack_glance_up') + { gridPos: { x: 12, y: 1, w: 3, h: 3 } },
        statusPanel('Placement', 'openstack_placement_up') + { gridPos: { x: 15, y: 1, w: 3, h: 3 } },
        statusPanel('Gnocchi', 'openstack_gnocchi_up') + { gridPos: { x: 18, y: 1, w: 3, h: 3 } },
        statusPanel('Ironic', 'openstack_ironic_up') + { gridPos: { x: 21, y: 1, w: 3, h: 3 } },
        statusPanel('Designate', 'openstack_designate_up') + { gridPos: { x: 0, y: 4, w: 3, h: 3 } },
        statusPanel('LoadBalancer', 'openstack_loadbalancer_up') + { gridPos: { x: 3, y: 4, w: 3, h: 3 } },
        statusPanel('Object Store', 'openstack_object_store_up') + { gridPos: { x: 6, y: 4, w: 3, h: 3 } },
        row.new('Resource Usage') + { gridPos: { x: 0, y: 5, w: 24, h: 1 } },
        cpuUsagePanel { gridPos: { x: 0, y: 5, w: 8, h: 8 } },
        overallMemoryUsagePanel { gridPos: { x: 8, y: 5, w: 8, h: 8 } },
        localStoragePanel { gridPos: { x: 16, y: 5, w: 8, h: 8 } },
        row.new('Keystone') + { gridPos: { x: 0, y: 6, w: 24, h: 1 } },
        statusPanel('Keystone', 'openstack_identity_up') + { gridPos: { x: 0, y: 7, w: 3, h: 3 } },
        groupsPanel { gridPos: { x: 0, y: 10, w: 3, h: 3 } },
        domainsPanel { gridPos: { x: 0, y: 13, w: 3, h: 3 } },
        regionsPanel { gridPos: { x: 0, y: 16, w: 3, h: 3 } },
        projectsPanel { gridPos: { x: 3, y: 7, w: 21, h: 6 } },
        usersPanel { gridPos: { x: 3, y: 13, w: 21, h: 6 } },
        projectDetailsPanel { gridPos: { x: 0, y: 20, w: 24, h: 12 } },
        row.new('Nova') + { gridPos: { x: 0, y: 21, w: 24, h: 1 } },
        statusPanel('Nova', 'openstack_nova_up') + { gridPos: { x: 0, y: 22, w: 3, h: 5 } },
        novaAgentsUp { gridPos: { x: 0, y: 27, w: 3, h: 5 } },
        novaAgentsDown { gridPos: { x: 0, y: 32, w: 3, h: 5 } },
        vmsPanel { gridPos: { x: 3, y: 22, w: 11, h: 7 } },
        vcpuUsagePanel { gridPos: { x: 14, y: 22, w: 10, h: 7 } },
        memoryUsagePanel { gridPos: { x: 3, y: 29, w: 11, h: 8 } },
        instanceUsagePanel { gridPos: { x: 14, y: 29, w: 10, h: 8 } },
        novaAgentsStatusPanel { gridPos: { x: 0, y: 37, w: 24, h: 8 } },
        row.new('Neutron') + { gridPos: { x: 0, y: 45, w: 24, h: 1 } },
        statusPanel('Neutron', 'openstack_neutron_up') + { gridPos: { x: 0, y: 46, w: 3, h: 5 } },
        neutronAgentsUp { gridPos: { x: 0, y: 51, w: 3, h: 5 } },
        neutronAgentsDown { gridPos: { x: 0, y: 56, w: 3, h: 5 } },
        neutronNetworksPanel { gridPos: { x: 3, y: 46, w: 11, h: 10 } },
        neutronSubnetsPanel { gridPos: { x: 14, y: 46, w: 10, h: 10 } },
        neutronRoutersPanel { gridPos: { x: 3, y: 56, w: 11, h: 10 } },
        neutronPortsPanel { gridPos: { x: 14, y: 56, w: 10, h: 10 } },
        neutronFloatingIPsPanel { gridPos: { x: 3, y: 66, w: 11, h: 10 } },
        neutronIPsUsedBySubnetsPanel { gridPos: { x: 14, y: 66, w: 10, h: 10 } },
        securityGroupsPanel { gridPos: { x: 3, y: 76, w: 11, h: 10 } },
        routerDetailsPanel { gridPos: { x: 0, y: 86, w: 24, h: 10 } },
        portDetailsPanel { gridPos: { x: 0, y: 96, w: 24, h: 10 } },
        neutronAgentsStatusPanel { gridPos: { x: 0, y: 106, w: 24, h: 10 } },
        row.new('Cinder') + { gridPos: { x: 0, y: 116, w: 24, h: 1 } },
        statusPanel('Cinder', 'openstack_cinder_up') + { gridPos: { x: 0, y: 117, w: 3, h: 5 } },
        cinderAgentsUp { gridPos: { x: 0, y: 122, w: 3, h: 5 } },
        cinderAgentsDown { gridPos: { x: 0, y: 127, w: 3, h: 5 } },
        volumesPanel { gridPos: { x: 3, y: 117, w: 11, h: 8 } },
        volumeStatusPanel { gridPos: { x: 14, y: 117, w: 10, h: 8 } },
        volumeUsagePanel { gridPos: { x: 3, y: 125, w: 11, h: 8 } },
        backupUsagePanel { gridPos: { x: 14, y: 125, w: 10, h: 8 } },
        poolUsagePanel { gridPos: { x: 3, y: 133, w: 11, h: 8 } },
        snapshotsPanel { gridPos: { x: 14, y: 133, w: 10, h: 8 } },
        cinderAgentsStatusPanel { gridPos: { x: 0, y: 141, w: 24, h: 10 } },
        row.new('Glance') + { gridPos: { x: 0, y: 151, w: 24, h: 1 } },
        statusPanel('Glance', 'openstack_glance_up') + { gridPos: { x: 0, y: 152, w: 3, h: 8 } },
        glanceImageCountPanel { gridPos: { x: 3, y: 152, w: 21, h: 8 } },
        glanceImagesPanel { gridPos: { x: 0, y: 160, w: 24, h: 10 } },
      ];

      dashboard.new('OpenStack Overview')
      + dashboard.withUid($._config.grafanaDashboards.ids.openstack)
      + dashboard.withTags($._config.grafanaDashboards.tags.k8sApps)
      + dashboard.withEditable($._config.grafanaDashboards.editable)
      + dashboard.withRefresh($._config.grafanaDashboards.refresh)
      + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
      + $._config.grafanaDashboards.tooltip
      + dashboard.withTimezone('browser')
      + dashboard.withVariables([
        $.grafanaTemplates.datasourceTemplate(),
        $.grafanaTemplates.clusterTemplate('label_values(openstack_identity_up, cluster)'),
        $.grafanaTemplates.jobTemplate('label_values(openstack_identity_up{cluster="$cluster"},job)'),
        $.grafanaTemplates.instanceTemplate('label_values(openstack_identity_up{cluster="$cluster"},instance)'),
      ])
      + dashboard.withPanels(panels),
  },
}
