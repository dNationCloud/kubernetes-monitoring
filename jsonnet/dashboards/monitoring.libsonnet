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

/* Monitoring dashboard */
local grafana = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafana.dashboard;
local statPanel = grafana.panel.stat;
local row = grafana.panel.row;
local rowWidth = 24;

local getGridX(index, panelWidth) =
  /**
   * Compute element grid X coordinate based on index number
   *
   * @param index The index of element.
   * @param panelWidth Width of panels.
   * @return grid X coordinate as number.
  */
  local panelsInRow = std.floor(rowWidth / panelWidth);
  (index % panelsInRow) * panelWidth;
local getGridY(offset, index, panelWidth, panelHeight) =
  /**
   * Compute element grid Y coordinate based on index number
   *
   * @param offset Offset of Y position.
   * @param index The index of element.
   * @param panelWidth Width of panels.
   * @param panelHeight Height of panels.
   * @return grid Y coordinate as number.
  */
  local panelsInRow = std.floor(rowWidth / panelWidth);
  (std.floor(index / panelsInRow) * panelHeight) + offset;
local getClusterRowGridY(numOfClusters, panelWidth, panelHeight) =
  /**
   * Compute grid Y coordinate of host row based on number of clusters.
   *
   * @param numOfClusters The number of clusters above the row.
   * @param panelWidth Width of panels.
   * @param panelHeight Height of panels.
   * @return grid Y coordinate as number.
  */
  getGridY(2 + panelHeight, numOfClusters - 1, panelWidth, panelHeight);

local getHostRowGridY(numOfHosts, panelWidth, panelHeightHosts, panelHeightClusters) =
  /**
   * Compute grid Y coordinate of services row based on number of hosts.
   *
   * @param numOfHosts The number of hosts above the row.
   * @param panelWidth Width of panels.
   * @param panelHeightHosts Height of host panels.
   * @param panelHeightClusters Height of cluster panels.
   * @return grid Y coordinate as number.
  */
  getGridY(3 + panelHeightHosts + panelHeightClusters, numOfHosts - 1, panelWidth, panelHeightHosts);

{
  grafanaDashboards+::
    local maxWarnings = $._config.grafanaDashboards.constants.maxWarnings;
    local numOfClusters = if $.isClusterMonitoring() then std.length($._config.clusterMonitoring.clusters) else 0;
    local numOfHosts = if $.isHostMonitoring() then std.length($._config.hostMonitoring.hosts) else 0;
    local getUid(defaultUid, obj, templateGroup) = if $.isAnyDefault([obj], templateGroup) then defaultUid else $.getCustomUid([defaultUid, obj.name]);

    local statBase(title, p) =
      statPanel.new(title)
      + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
      + (if std.objectHas(p, 'colorMode') then statPanel.options.withColorMode(p.colorMode) else {})
      + (if std.objectHas(p, 'graphMode') then statPanel.options.withGraphMode(p.graphMode) else {})
      + (if std.objectHas(p, 'unit') then statPanel.standardOptions.withUnit(p.unit) else {})
      + (if std.objectHas(p, 'decimals') && p.decimals != null then statPanel.standardOptions.withDecimals(p.decimals) else {});

    if $.isHostMonitoring() || $.isClusterMonitoring() then
      {
        monitoring:
          local dNationLink =
            dashboard.link.link.new('dNation - Making Cloud Easy', 'https://www.dNation.cloud/')
            + dashboard.link.link.withIcon('cloud')
            + dashboard.link.link.options.withTargetBlank(true);

          local hostPanel(index, host) = [
            local panelHeight = tpl.panel.gridPos.h;
            local panelWidth = tpl.panel.gridPos.w;
            local gridX = if std.type(tpl.panel.gridPos.x) == 'number' then tpl.panel.gridPos.x else getGridX(index, panelWidth);
            local gridY = if std.type(tpl.panel.gridPos.y) == 'number' then tpl.panel.gridPos.y else getGridY(getClusterRowGridY(numOfClusters, $._config.templates.L0.k8s.main.panel.gridPos.w, $._config.templates.L0.k8s.main.panel.gridPos.h), index, panelWidth, panelHeight);
            statBase('Host %s' % host.name, tpl.panel)
            + statPanel.queryOptions.withTargets([{ type: 'single', instant: true, expr: tpl.panel.expr % { job: std.join('|', $.getAlertJobs(host)), groupHost: $._config.prometheusRules.alertGroupHost, groupHostApp: $._config.prometheusRules.alertGroupHostApp, maxWarnings: maxWarnings }, refId: 'A' }])
            + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds(tpl.panel.thresholds))
            + statPanel.standardOptions.withMappings(tpl.panel.mappings)
            + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs(
              if std.length(tpl.panel.dataLinks) > 0 then tpl.panel.dataLinks % { job: host.jobName }
              else [{ title: 'Host Monitoring', url: '/d/%s?%s&var-job=%s' % [getUid($._config.grafanaDashboards.ids.hostMonitoring, host, $._config.templates.L1.host), $._config.grafanaDashboards.dataLinkCommonArgsNoCluster, host.jobName] }]
            ))
            + { gridPos: { x: gridX, y: gridY, w: panelWidth, h: panelHeight } }
            for tpl in $.getTemplates($._config.templates.L0.host, host)
            if (std.objectHas(tpl, 'panel') && tpl.panel != {})
          ];

          local clusterPanel(index, cluster) = [
            local panelHeight = tpl.panel.gridPos.h;
            local panelWidth = tpl.panel.gridPos.w;
            local clusterLabel = cluster.label;
            local dataLinkCommonArgs = std.strReplace($._config.grafanaDashboards.dataLinkCommonArgs, '$cluster', clusterLabel);
            local gridX = if std.type(tpl.panel.gridPos.x) == 'number' then tpl.panel.gridPos.x else getGridX(index, panelWidth);
            local gridY = if std.type(tpl.panel.gridPos.y) == 'number' then tpl.panel.gridPos.y else getGridY(1, index, panelWidth, panelHeight);
            local isVM = (std.objectHas(cluster, 'vms') && std.length(cluster.vms) > 0);
            statBase('Cluster %s' % cluster.name, tpl.panel)
            + statPanel.queryOptions.withTargets([{ type: 'single', instant: true, expr: tpl.panel.expr % { cluster: clusterLabel, groupCluster: $._config.prometheusRules.alertGroupCluster + (if isVM then '|' + $._config.prometheusRules.alertGroupClusterVM else ''), groupApp: $._config.prometheusRules.alertGroupClusterApp + (if isVM then '|' + $._config.prometheusRules.alertGroupClusterVMApp else ''), maxWarnings: maxWarnings }, refId: 'A' }])
            + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds(tpl.panel.thresholds))
            + statPanel.standardOptions.withMappings(tpl.panel.mappings)
            + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs(
              if std.length(tpl.panel.dataLinks) > 0 then tpl.panel.dataLinks
              else [{ title: 'Observer Monitoring', url: '/d/%s?%s' % [getUid($._config.grafanaDashboards.ids.k8sMonitoring, cluster, $._config.templates.L1.k8s), dataLinkCommonArgs] }]
            ))
            + { gridPos: { x: gridX, y: gridY, w: panelWidth, h: panelHeight } }
            for tpl in $.getTemplates($._config.templates.L0.k8s, cluster)
            if (std.objectHas(tpl, 'panel') && tpl.panel != {})
          ];

          local blackBoxPanels = [
            local panelHeight = tpl.panel.gridPos.h;
            local panelWidth = tpl.panel.gridPos.w;
            local dataLinkCommonArgsBlackbox = $._config.grafanaDashboards.dataLinkCommonArgsBlackbox;
            local gridX = if std.type(tpl.panel.gridPos.x) == 'number' then tpl.panel.gridPos.x else 0;
            local gridY = if std.type(tpl.panel.gridPos.y) == 'number' then tpl.panel.gridPos.y else getHostRowGridY(numOfHosts, $._config.templates.L0.host.main.panel.gridPos.w, $._config.templates.L0.host.main.panel.gridPos.h, $._config.templates.L0.k8s.main.panel.gridPos.h);
            statBase('Service $target', tpl.panel)
            + statPanel.panelOptions.withRepeat('target') + statPanel.panelOptions.withMaxPerRow(4)
            + statPanel.queryOptions.withTargets([{ type: 'single', instant: true, expr: tpl.panel.expr % { target: '$target' }, refId: 'A' }])
            + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds(tpl.panel.thresholds))
            + statPanel.standardOptions.withMappings(tpl.panel.mappings)
            + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs(
              if std.length(tpl.panel.dataLinks) > 0 then tpl.panel.dataLinks
              else [{ title: 'Blackbox Exporter (HTTP prober)', url: '/d/%s?%s' % ['blackbox', dataLinkCommonArgsBlackbox] }]
            ))
            + { gridPos: { x: gridX, y: gridY, w: panelWidth, h: panelHeight } }
            for tpl in $.getTemplates($._config.templates.L0.blackbox)
            if (std.objectHas(tpl, 'panel') && tpl.panel != {})
          ];

          local hostPanels = std.flattenArrays([hostPanel(host.index, host.item) for host in $.zipWithIndex($._config.hostMonitoring.hosts)]);
          local clusterPanels = std.flattenArrays([clusterPanel(cluster.index, cluster.item) for cluster in $.zipWithIndex($._config.clusterMonitoring.clusters)]);

          dashboard.new('Infrastructure services monitoring')
          + dashboard.withUid($._config.grafanaDashboards.ids.monitoring)
          + dashboard.withTags($._config.grafanaDashboards.tags.k8sMonitoringMain)
          + dashboard.withEditable($._config.grafanaDashboards.editable) + dashboard.withRefresh($._config.grafanaDashboards.refresh)
          + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
          + $._config.grafanaDashboards.tooltip
          + dashboard.withTimezone('browser')
          + dashboard.withLinks([dNationLink])
          + dashboard.withVariables([
            $.grafanaTemplates.datasourceTemplate(),
            $.grafanaTemplates.alertManagerTemplate(),
            $.grafanaTemplates.targetTemplate('label_values(probe_success{endpoint="http"},target)', multi=true, includeAll=true, current='All'),
          ])
          + dashboard.withPanels(
            (if $.isClusterMonitoring() then [row.new('Clusters') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } }] + clusterPanels else [])
            + (if $.isHostMonitoring() then [row.new('Hosts') + { gridPos: { x: 0, y: getClusterRowGridY(numOfClusters, $._config.templates.L0.k8s.main.panel.gridPos.w, $._config.templates.L0.k8s.main.panel.gridPos.h) - 1, w: 24, h: 1 } }] + hostPanels else [])
            + (if $.isBlackBoxMonitoring() then [row.new('Services') + { gridPos: { x: 0, y: getHostRowGridY(numOfHosts, $._config.templates.L0.host.main.panel.gridPos.w, $._config.templates.L0.host.main.panel.gridPos.h, $._config.templates.L0.k8s.main.panel.gridPos.h) - 1, w: 24, h: 1 } }] + blackBoxPanels else [])
          ),
      } else {},
}
