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

/**
 * Compute element grid X coordinate based on index number
 *
 * @param index The index of element.
 * @param panelWidth Width of panels.
 * @return grid X coordinate as number.
*/
local getGridX(index, panelWidth) = (index % std.floor(rowWidth / panelWidth)) * panelWidth;

/**
 * Compute element grid Y coordinate based on index number
 *
 * @param offset Offset of Y position.
 * @param index The index of element.
 * @param panelWidth Width of panels.
 * @param panelHeight Height of panels.
 * @return grid Y coordinate as number.
*/
local getGridY(offset, index, panelWidth, panelHeight) = (std.floor(index / std.floor(rowWidth / panelWidth)) * panelHeight) + offset;

{
  grafanaDashboards+::
    local maxWarnings = $._config.grafanaDashboards.constants.maxWarnings;
    local color = $._config.grafanaDashboards.color;
    local getUid(defaultUid, obj, templateGroup) = if $.isAnyDefault([obj], templateGroup) then defaultUid else $.getCustomUid([defaultUid, obj.name]);

    if $.isKaasMonitoring() then
      {
        kaasMonitoring:
          local dNationLink =
            dashboard.link.link.new('dNation - Making Cloud Easy', 'https://www.dNation.cloud/')
            + dashboard.link.link.withIcon('cloud')
            + dashboard.link.link.options.withTargetBlank(true);

          local clusterPanel(index, cluster) = [
            local panelHeight = tpl.panel.gridPos.h;
            local panelWidth = tpl.panel.gridPos.w;
            local gridX = if std.type(tpl.panel.gridPos.x) == 'number' then tpl.panel.gridPos.x else getGridX(index, panelWidth);
            local gridY = if std.type(tpl.panel.gridPos.y) == 'number' then tpl.panel.gridPos.y else getGridY(4, index, panelWidth, panelHeight);
            (statPanel.new('Cluster %s' % '$cluster')
             + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
             + (if std.objectHas(tpl.panel, 'colorMode') then statPanel.options.withColorMode(tpl.panel.colorMode) else {})
             + (if std.objectHas(tpl.panel, 'graphMode') then statPanel.options.withGraphMode(tpl.panel.graphMode) else {})
             + (if std.objectHas(tpl.panel, 'unit') then statPanel.standardOptions.withUnit(tpl.panel.unit) else {})
             + (if std.objectHas(tpl.panel, 'decimals') && tpl.panel.decimals != null then statPanel.standardOptions.withDecimals(tpl.panel.decimals) else {})
             + statPanel.panelOptions.withRepeat('cluster') + statPanel.panelOptions.withMaxPerRow(4))
            + statPanel.queryOptions.withTargets([{ type: 'single', instant: true, expr: tpl.panel.expr % { cluster: '$cluster', groupCluster: $._config.prometheusRules.alertGroupCluster, groupApp: $._config.prometheusRules.alertGroupClusterApp, maxWarnings: maxWarnings }, refId: 'A' }])
            + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps($.grafanaThresholds(tpl.panel.thresholds))
            + statPanel.standardOptions.withMappings(tpl.panel.mappings)
            + statPanel.standardOptions.withLinks($.updateDataLinksCommonArgs(
              if std.length(tpl.panel.dataLinks) > 0 then tpl.panel.dataLinks
              else [{ title: 'KaaS Monitoring', url: '/d/%s?%s' % [getUid($._config.grafanaDashboards.ids.kaasL1Monitoring, cluster, $._config.templates.L1.k8s), $._config.grafanaDashboards.dataLinkCommonArgs] }]
            ))
            + { gridPos: { x: gridX, y: gridY, w: panelWidth, h: panelHeight } }
            for tpl in $.getTemplates($._config.templates.L0.kaas, cluster)
            if (std.objectHas(tpl, 'panel') && tpl.panel != {})
          ];

          local statBase(title, expr, steps) =
            statPanel.new(title)
            + statPanel.queryOptions.withDatasource('prometheus', '$datasource')
            + statPanel.options.withGraphMode('none') + statPanel.options.withColorMode('background') + statPanel.options.reduceOptions.withCalcs(['last'])
            + statPanel.standardOptions.thresholds.withMode('absolute') + statPanel.standardOptions.thresholds.withSteps(steps)
            + statPanel.queryOptions.withTargets([{ type: 'single', expr: expr, refId: 'A' }]);

          local statusNormalPanel = statBase('Number of k8s clusters in normal state', 'sum(group by (cluster) (kaas{cluster=~"$cluster"}) and group by (cluster) (up{cluster=~"$cluster"}) unless group by (cluster) (ALERTS{alertname!="Watchdog", cluster=~"$cluster", alertstate="firing", severity=~"warning|critical", alertgroup=~"Cluster|ClusterApp"}) OR on() vector(0)) OR on() vector(0)', [{ color: color.green, value: null }]);
          local statusWarningPanel = statBase('Number of k8s clusters in warning state', 'sum(group by (cluster) (ALERTS{alertname!="Watchdog", cluster=~"$cluster", alertstate="firing", severity="warning", alertgroup=~"Cluster|ClusterApp"}) unless group by (cluster) (ALERTS{alertname!="Watchdog", cluster=~"$cluster", alertstate="firing", severity="critical", alertgroup=~"Cluster|ClusterApp"})) or on() vector(0)', [{ color: color.orange, value: null }]);
          local statusCriticalPanel = statBase('Number of k8s clusters in critical state', 'count(count by (cluster) (ALERTS{cluster=~"$cluster", alertname!="Watchdog", alertstate=~"firing", severity="critical", alertgroup=~"Cluster|ClusterApp"})) OR on() vector(0)', [{ color: color.red, value: null }]);
          local clusterPanels = std.flattenArrays([clusterPanel(cluster.index, cluster.item) for cluster in $.zipWithIndex($._config.kaasMonitoring.clusters)]);

          dashboard.new('KaaS Monitoring')
          + dashboard.withUid($._config.grafanaDashboards.ids.kaasMonitoring)
          + dashboard.withTags($._config.grafanaDashboards.tags.kaasMonitoringMain)
          + dashboard.withEditable($._config.grafanaDashboards.editable) + dashboard.withRefresh($._config.grafanaDashboards.refresh)
          + dashboard.time.withFrom($._config.grafanaDashboards.time_from)
          + $._config.grafanaDashboards.tooltip
          + dashboard.withTimezone('browser')
          + dashboard.withLinks([dNationLink])
          + dashboard.withVariables([
            $.grafanaTemplates.datasourceTemplate(),
            $.grafanaTemplates.alertManagerTemplate(),
            $.grafanaTemplates.clusterTemplate('label_values(kaas, cluster)', multi=true, includeAll=true, current='All'),
          ])
          + dashboard.withPanels([
            row.new('KaaS Status') + { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
            statusNormalPanel { gridPos: { x: 0, y: 1, w: 8, h: 3 } },
            statusWarningPanel { gridPos: { x: 8, y: 1, w: 8, h: 3 } },
            statusCriticalPanel { gridPos: { x: 16, y: 1, w: 8, h: 3 } },
            row.new('KaaS Monitoring') + { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
          ] + clusterPanels),
      } else {},
}
