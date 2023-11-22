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

local grafana = (import 'grafonnet/grafana.libsonnet');
local dashboard = grafana.dashboard;
local statPanel = grafana.statPanel;
local row = grafana.row;
local link = grafana.link;

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
  local columnIndex = index % panelsInRow;
  columnIndex * panelWidth;

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
  local rowIndex = std.floor(index / panelsInRow);
  (rowIndex * panelHeight) + offset;

{
  grafanaDashboards+::

    local maxWarnings = $._config.grafanaDashboards.constants.maxWarnings;

    local getUid(defaultUid, obj, templateGroup) =
      if $.isAnyDefault([obj], templateGroup) then defaultUid else $.getCustomUid([defaultUid, obj.name]);

    if $.isKaasMonitoring() then
      {
        kaasMonitoring:
          local dNationLink =
            link.dashboards(
              title='dNation - Making Cloud Easy',
              tags=[],
              icon='cloud',
              url='https://www.dNation.cloud/',
              type='link',
              targetBlank=true,
            );

          local clusterPanel(index, cluster) = [

            local panelHeight = tpl.panel.gridPos.h;
            local panelWidth = tpl.panel.gridPos.w;

            local dataLinkCommonArgs = $._config.grafanaDashboards.dataLinkCommonArgs;

            local gridX =
              if std.type(tpl.panel.gridPos.x) == 'number' then
                tpl.panel.gridPos.x
              else
                getGridX(index, panelWidth);

            local gridY =
              if std.type(tpl.panel.gridPos.y) == 'number' then
                tpl.panel.gridPos.y
              else
                getGridY(4, index, panelWidth, panelHeight);

            statPanel.new(
              title='Cluster %s' % '$cluster',
              datasource=tpl.panel.datasource,
              graphMode=tpl.panel.graphMode,
              colorMode=tpl.panel.colorMode,
              unit=tpl.panel.unit,
              repeat='cluster',
              maxPerRow=4,
              decimals=tpl.panel.decimals,
            )
            .addTarget(
              {
                type: 'single',
                instant: true,
                expr: tpl.panel.expr %
                      {
                        cluster: '$cluster',
                        groupCluster: $._config.prometheusRules.alertGroupCluster,
                        groupApp: $._config.prometheusRules.alertGroupClusterApp,
                        maxWarnings: maxWarnings,
                      },
              }
            )
            .addThresholds($.grafanaThresholds(tpl.panel.thresholds))
            .addMappings(tpl.panel.mappings)
            .addDataLinks(
              $.updateDataLinksCommonArgs(
                if std.length(tpl.panel.dataLinks) > 0 then
                  tpl.panel.dataLinks
                else
                  [{ title: 'KaaS Monitoring', url: '/d/%s?%s' % [getUid($._config.grafanaDashboards.ids.kaasL1Monitoring, cluster, $._config.templates.L1.k8s), dataLinkCommonArgs] }]
              )
            )
            {
              gridPos: {
                x: gridX,
                y: gridY,
                w: panelWidth,
                h: panelHeight,
              },
            }
            for tpl in $.getTemplates($._config.templates.L0.kaas, cluster)
            if (std.objectHas(tpl, 'panel') && tpl.panel != {})
          ];

          local statusPanels(title, expr) =
            statPanel.new(
              title=title,
              datasource='$datasource',
              graphMode='none',
              colorMode='background',
              reducerFunction='last',
            )
            .addTarget({ type: 'single', expr: expr });

          local statusNormalPanel =
            statusPanels(
              title='Number of k8s clusters in normal state',
              expr='count(count by (cluster) (kaas{cluster=~"$cluster"})) - (count(count by (cluster)(ALERTS{alertname!="Watchdog", cluster=~"$cluster", alertstate="firing", severity=~"warning|critical", alertgroup=~"Cluster|ClusterApp"})) OR on() vector(0)) OR on() vector(0)'
            )
            .addThresholds(
              [
                { color: $._config.grafanaDashboards.color.green, value: null },
              ]
            );

          local statusWarningPanel =
            statusPanels(
              title='Number of k8s clusters in warning state',
              expr='group by (cluster) (ALERTS{alertname!="Watchdog", cluster=~"$cluster", alertstate="firing", severity="warning", alertgroup=~"Cluster|ClusterApp"}) or on() vector(0) unless group by (cluster) (ALERTS{alertname!="Watchdog", cluster=~"$cluster", alertstate="firing", severity="critical", alertgroup=~"Cluster|ClusterApp"}) or on() vector(0)'
            )
            .addThresholds(
              [
                { color: $._config.grafanaDashboards.color.orange, value: null },
              ]
            );

          local statusCriticalPanel =
            statusPanels(
              title='Number of k8s clusters in critical state',
              expr='count(count by (cluster) (ALERTS{cluster=~"$cluster", alertname!="Watchdog", alertstate=~"firing", severity="critical", alertgroup=~"Cluster|ClusterApp"})) OR on() vector(0)'
            )
            .addThresholds(
              [
                { color: $._config.grafanaDashboards.color.red, value: null },
              ]
            );

          local clusterPanels =
            std.flattenArrays([
              clusterPanel(cluster.index, cluster.item)
              for cluster in $.zipWithIndex($._config.kaasMonitoring.clusters)
            ]);

          dashboard.new(
            'KaaS Monitoring',
            editable=$._config.grafanaDashboards.editable,
            graphTooltip=$._config.grafanaDashboards.tooltip,
            refresh=$._config.grafanaDashboards.refresh,
            time_from=$._config.grafanaDashboards.time_from,
            tags=$._config.grafanaDashboards.tags.kaasMonitoringMain,
            uid=$._config.grafanaDashboards.ids.kaasMonitoring,
          )
          .addLink(dNationLink)
          .addTemplates([
            $.grafanaTemplates.datasourceTemplate(),
            $.grafanaTemplates.alertManagerTemplate(),
            $.grafanaTemplates.clusterTemplate('label_values(kaas, cluster)', multi=true, includeAll=true, current='All'),
          ])
          .addPanels(
            (
              if $.isKaasMonitoring() then
                [
                  row.new('KaaS Status') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
                  statusNormalPanel { gridPos: { x: 0, y: 1, w: 8, h: 3 } },
                  statusWarningPanel { gridPos: { x: 8, y: 1, w: 8, h: 3 } },
                  statusCriticalPanel { gridPos: { x: 16, y: 1, w: 8, h: 3 } },
                  row.new('KaaS Monitoring') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
                ] + clusterPanels
              else []
            )
          ),
      } else {},
}
