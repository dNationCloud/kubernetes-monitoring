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
local template = grafana.template;
local row = grafana.row;
local link = grafana.link;

local rowWidth = 24;

local getGridX(index, panelWidth) =
  /**
   * Compute element grid X coordinate based on index number
   *
   * @param index The index of element.
   * @return grid X coordinate as number.
  */
  (index * panelWidth) % rowWidth;

local getGridY(offset, index, panelWidth, panelHeight) =
  /**
   * Compute element grid Y coordinate based on index number
   *
   * @param offset Offset of Y position.
   * @param index The index of element.
   * @return grid Y coordinate as number.
  */
  std.floor((index * panelWidth) / rowWidth) * panelHeight + offset;

local getClusterRowGridY(numOfClusters, panelWidth, panelHeight) =
  /**
   * Compute grid Y coordinate of host row based on number of clusters.
   *
   * @param index The index of host.
   * @return grid Y coordinate as number.
  */
  getGridY(2 + panelHeight, numOfClusters - 1, panelWidth, panelHeight);

{
  grafanaDashboards+::

    local maxWarnings = $._config.grafanaDashboards.constants.maxWarnings;

    local isHostMonitoring =
      std.length($._config.hostMonitoring.hosts) > 0 && $._config.hostMonitoring.enabled;

    local isClusterMonitoring =
      std.length($._config.clusterMonitoring.clusters) > 0 && $._config.clusterMonitoring.enabled;

    local numOfClusters =
      if isClusterMonitoring then std.length($._config.clusterMonitoring.clusters) else 0;

    local getUid(defaultId, obj) =
      if $.isAnyDefault([obj]) then defaultId else defaultId + std.asciiLower(obj.name);

    if isHostMonitoring || isClusterMonitoring then
      {
        monitoring:
          local dNationLink =
            link.dashboards(
              title='dNation - Making Cloud Easy',
              tags=[],
              icon='cloud',
              url='https://www.dNation.cloud/',
              type='link',
              targetBlank=true,
            );

          local hostPanel(index, host) = [

            local panelHeight = tpl.panel.gridPos.h;
            local panelWidth = tpl.panel.gridPos.w;

            local gridX =
              if std.type(tpl.panel.gridPos.x) == 'number' then
                tpl.panel.gridPos.x
              else
                getGridX(index, panelWidth);

            local gridY =
              if std.type(tpl.panel.gridPos.y) == 'number' then
                tpl.panel.gridPos.y
              else
                getGridY(getClusterRowGridY(numOfClusters, $._config.templates.layerL0.k8s.main.panel.gridPos.w, $._config.templates.layerL0.k8s.main.panel.gridPos.h), index, panelWidth, panelHeight);

            statPanel.new(
              title='Host %s' % host.name,
              datasource=tpl.panel.datasource,
              graphMode=tpl.panel.graphMode,
              colorMode=tpl.panel.colorMode,
            )
            .addTarget({ type: 'single', instant: true, expr: tpl.panel.expr % { job: std.join('|', $.getAlertJobs(host)), groupHost: $._config.prometheusRules.alertGroupHost, groupHostApp: $._config.prometheusRules.alertGroupHostApp, maxWarnings: maxWarnings } })
            .addThresholds($.grafanaThresholds(tpl.panel.thresholds))
            .addMappings(tpl.panel.mappings)
            .addDataLinks(
              if std.length(tpl.panel.dataLinks) > 0 then
                tpl.panel.dataLinks
              else
                [{ title: 'Host Monitoring', url: '/d/%s?%s&var-job=%s' % [getUid($._config.grafanaDashboards.ids.hostMonitoring, host), $._config.grafanaDashboards.dataLinkCommonArgs, host.jobName] }]
            )
            {
              gridPos: {
                x: gridX,
                y: gridY,
                w: panelWidth,
                h: panelHeight,
              },
            }
            for tpl in $.getTemplates($._config.templates.layerL0.host, host)
            if (std.objectHas(tpl, 'panel') && tpl.panel != {})
          ];

          local clusterPanel(index, cluster) = [

            local panelHeight = tpl.panel.gridPos.h;
            local panelWidth = tpl.panel.gridPos.w;

            // multiple cluster monitoring isn't supported yet, replace lines when adding support for multiple clusters
            local dataLinkCommonArgs = $._config.grafanaDashboards.dataLinkCommonArgs;
            //local dataLinkCommonArgs = std.strReplace($._config.grafanaDashboards.dataLinkCommonArgs, '$cluster|', cluster.name);

            // when multiple cluster will be supported, cluster variable will in expr will be cluster name
            local localCluster = { name: '' };

            local gridX =
              if std.type(tpl.panel.gridPos.x) == 'number' then
                tpl.panel.gridPos.x
              else
                getGridX(index, panelWidth);

            local gridY =
              if std.type(tpl.panel.gridPos.y) == 'number' then
                tpl.panel.gridPos.y
              else
                getGridY(1, index, panelWidth, panelHeight);

            statPanel.new(
              title='Cluster %s' % cluster.name,
              datasource=tpl.panel.datasource,
              graphMode=tpl.panel.graphMode,
              colorMode=tpl.panel.colorMode,
            )
            .addTarget({ type: 'single', instant: true, expr: tpl.panel.expr % { cluster: localCluster.name, groupCluster: $._config.prometheusRules.alertGroupCluster, groupApp: $._config.prometheusRules.alertGroupClusterApp, maxWarnings: maxWarnings } })
            .addThresholds($.grafanaThresholds(tpl.panel.thresholds))
            .addMappings(tpl.panel.mappings)
            .addDataLinks(
              if std.length(tpl.panel.dataLinks) > 0 then
                tpl.panel.dataLinks
              else
                [{ title: 'Kubernetes Monitoring', url: '/d/%s?%s' % [getUid($._config.grafanaDashboards.ids.k8sMonitoring, cluster), dataLinkCommonArgs] }]
            )
            {
              gridPos: {
                x: gridX,
                y: gridY,
                w: panelWidth,
                h: panelHeight,
              },
            }
            for tpl in $.getTemplates($._config.templates.layerL0.k8s, cluster)
            if (std.objectHas(tpl, 'panel') && tpl.panel != {})
          ];

          local datasourceTemplate =
            template.datasource(
              query='prometheus',
              name='datasource',
              current=null,
              label='Datasource',
            );

          local alertManagerTemplate =
            template.datasource(
              query='camptocamp-prometheus-alertmanager-datasource',
              name='alertmanager',
              current=null,
              label='AlertManager',
              hide='variable',
            );

          local hostPanels =
            std.flattenArrays([
              hostPanel(host.index, host.item)
              for host in $.zipWithIndex($._config.hostMonitoring.hosts)
            ]);

          local clusterPanels =
            // multiple cluster monitoring isn't supported yet, always take only first cluster
            std.flattenArrays([
              clusterPanel(cluster.index, cluster.item)
              for cluster in $.zipWithIndex($._config.clusterMonitoring.clusters)
            ]);

          dashboard.new(
            'Monitoring',
            editable=$._config.grafanaDashboards.editable,
            graphTooltip=$._config.grafanaDashboards.tooltip,
            refresh=$._config.grafanaDashboards.refresh,
            time_from=$._config.grafanaDashboards.time_from,
            tags=$._config.grafanaDashboards.tags.k8sMonitoringMain,
            uid=$._config.grafanaDashboards.ids.monitoring,
          )
          .addLink(dNationLink)
          .addTemplates([datasourceTemplate, alertManagerTemplate])
          .addPanels(
            (if isClusterMonitoring then
               [row.new('Kubernetes Monitoring') { gridPos: { x: 0, y: 0, w: 24, h: 1 } }] + clusterPanels
             else []) +
            (if isHostMonitoring then
               [
                 row.new('Host Monitoring') {
                   local rowY = getClusterRowGridY(numOfClusters, $._config.templates.layerL0.k8s.main.panel.gridPos.w, $._config.templates.layerL0.k8s.main.panel.gridPos.h) - 1,
                   gridPos: { x: 0, y: rowY, w: 24, h: 1 },
                 },
               ] + hostPanels
             else [])
          ),
      } else {},
}
