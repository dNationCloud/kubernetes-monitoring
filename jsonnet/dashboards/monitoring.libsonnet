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


local maxWarnings = 10000;
local panelWidth = 4;
local panelHeight = 3;
local rowWidth = 24;


local getGridX(index) =
  /**
   * Compute element grid X coordinate based on index number
   *
   * @param index The index of element.
   * @return grid X coordinate as number.
  */
  (index * panelWidth) % rowWidth;

local getGridY(offset, index) =
  /**
   * Compute element grid Y coordinate based on index number
   *
   * @param offset Offset of Y position.
   * @param index The index of element.
   * @return grid Y coordinate as number.
  */
  std.floor((index * panelWidth) / rowWidth) * panelHeight + offset;

local getClusterRowGridY(numOfHosts) =
  /**
   * Compute grid Y coordinate of cluster row based on number of hosts.
   *
   * @param index The index of host.
   * @return grid Y coordinate as number.
  */
  getGridY(2 + panelHeight, numOfHosts - 1);

{
  grafanaDashboards+::

    local isHostMonitoring =
      std.length($._config.hostMonitoring.hosts) > 0 && $._config.hostMonitoring.enabled;

    local isClusterMonitoring =
      std.length($._config.clusterMonitoring.clusters) > 0 && $._config.clusterMonitoring.enabled;

    local numOfHosts =
      if isHostMonitoring then std.length($._config.hostMonitoring.hosts) else 0;

    local getUid(defaultId, obj) =
      if $.isAnyDefault([obj]) then defaultId else defaultId + std.asciiLower(obj.name);

    local getJob(obj) =
      if $.isAnyDefault([obj]) then '&var-job=%s' % obj.jobName else '';

    local getClusterVar(cluster) = '&var-cluster=%s' % cluster.name;

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

          local alertPanel(title, expr) =

            local rangeMaps = [
              { from: 0, text: 'OK', to: 0, type: 2, value: '' },
              { from: 1, text: 'Warning', to: maxWarnings, type: 2, value: '' },
              { from: maxWarnings, text: 'Critical', to: $._config.grafanaDashboards.constants.infinity, type: 2, value: '' },
            ];

            statPanel.new(
              title=title,
              datasource='$datasource',
              graphMode='none',
              colorMode='background',
            )
            .addTarget({ type: 'single', expr: expr })
            .addThresholds($.grafanaThresholds({ operator: '>=', warning: 1, critical: maxWarnings }))
            .addMappings(rangeMaps);

          local hostAlertsPanel(host) =
            alertPanel(
              title='Host %s' % host.name,
              expr=|||
                sum(ALERTS{alertname!="Watchdog", severity="warning", job=~"%(job)s", alertgroup=~"%(groupHost)s|%(groupHostApp)s"} OR on() vector(0)) +
                sum(ALERTS{alertname!="Watchdog", severity="critical", job=~"%(job)s", alertgroup=~"%(groupHost)s|%(groupHostApp)s"} OR on() vector(0)) * %(maxWarnings)d
              ||| % { job: host.jobName, groupHost: $._config.prometheusRules.alertGroupHost, groupHostApp: $._config.prometheusRules.alertGroupHostApp, maxWarnings: maxWarnings },
            )
            .addDataLink({ title: 'Host Monitoring', url: '/d/%s?%s%s' % [getUid($._config.grafanaDashboards.ids.hostMonitoring, host), $._config.grafanaDashboards.dataLinkCommonArgs, getJob(host)] });

          local clusterAlertsPanel(cluster) =

            // multiple cluster monitoring isn't supported yet, replace lines when adding support for multiple clusters
            local dataLinkCommonArgs = $._config.grafanaDashboards.dataLinkCommonArgs;
            //local dataLinkCommonArgs = std.strReplace($._config.grafanaDashboards.dataLinkCommonArgs, '$cluster|', cluster.name);

            // when multiple cluster will be supported, cluster variable will in expr will be cluster name
            local localCluster = { name: '' };

            alertPanel(
              title='Cluster %s' % cluster.name,
              expr=|||
                sum(ALERTS{alertname!="Watchdog", cluster=~"%(cluster)s", severity="warning", alertgroup=~"%(groupCluster)s|%(groupApp)s"} OR on() vector(0)) +
                sum(ALERTS{alertname!="Watchdog", cluster=~"%(cluster)s", severity="critical", alertgroup=~"%(groupCluster)s|%(groupApp)s"} OR on() vector(0)) * %(maxWarnings)d
              ||| % { cluster: localCluster.name, groupCluster: $._config.prometheusRules.alertGroupCluster, groupApp: $._config.prometheusRules.alertGroupClusterApp, maxWarnings: maxWarnings },
            )
            .addDataLink({ title: 'Kubernetes Monitoring', url: '/d/%s?%s%s' % [getUid($._config.grafanaDashboards.ids.k8sMonitoring, cluster), dataLinkCommonArgs, getClusterVar(localCluster)] });

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

          local hostPanel(index, host) =
            local gridX = getGridX(index);
            local gridY = getGridY(1, index);

            [hostAlertsPanel(host) { gridPos: { x: gridX, y: gridY, w: panelWidth, h: panelHeight } }];

          local clusterPanel(index, cluster) =
            local gridX = getGridX(index);
            local gridY = getGridY(getClusterRowGridY(numOfHosts) + 1, index);

            [clusterAlertsPanel(cluster) { gridPos: { x: gridX, y: gridY, w: panelWidth, h: panelHeight } }];

          local hostPanels =
            std.flattenArrays([
              hostPanel(host.index, host.item)
              for host in $.zipWithIndex($._config.hostMonitoring.hosts)
            ]);

          local clusterPanels =
            // multiple cluster monitoring isn't supported yet, always take only first cluster
            local firstCluster =
              (if std.length($._config.clusterMonitoring.clusters) > 0 then
                 [$._config.clusterMonitoring.clusters[0]]
               else []);

            std.flattenArrays([
              clusterPanel(cluster.index, cluster.item)
              for cluster in $.zipWithIndex(firstCluster)
              //for cluster in $.zipWithIndex($._config.clusterMonitoring.clusters)
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
            (if isHostMonitoring then
               [row.new('Host Monitoring') { gridPos: { x: 0, y: 0, w: 24, h: 1 } }] + hostPanels
             else []) +
            (if isClusterMonitoring then
               [row.new('Kubernetes Monitoring') { gridPos: { x: 0, y: getClusterRowGridY(numOfHosts), w: 24, h: 1 } }] + clusterPanels
             else [])
          ),
      } else {},
}
