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

/* K8s main dashboard */

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local statPanel = grafana.statPanel;
local template = grafana.template;
local row = grafana.row;
local link = grafana.link;
local text = grafana.text;

{
  grafanaDashboards+:: {
    'k8s-monitoring':
      local appMonitoringLink =
        link.dashboards(
          title='Application Monitoring',
          tags=[],
          url='/d/%s' % $._config.grafanaDashboards.ids.appMonitoring,
          type='link',
        );

      local hostMonitoringLink =
        link.dashboards(
          title='Host Monitoring',
          tags=[],
          url='/d/%s' % $._config.grafanaDashboards.ids.hostMonitoring,
          type='link',
        );

      local containerLink =
        link.dashboards(
          title=if $._config.grafanaDashboards.isLoki then 'Logs Container' else 'Container Detail',
          tags=[],
          icon='dashboard',
          url='/d/%s' % $._config.grafanaDashboards.ids.containerDetail,
          type='link',
        );

      local explorerLink =
        link.dashboards(
          title='Logs Explorer',
          tags=[],
          icon='doc',
          url='/explore?orgId=1&left=%5B%22now-7d%22,%22now%22,%22$datasource_logs%22,%7B%22expr%22:%22%7Bnamespace%3D%5C%22kube-system%5C%22,%20stream%3D%5C%22stderr%5C%22%7D%20%7C~%20%5C%22(%3Fi)error%5C%22%20!~%20%5C%22Final%20error%20received,%20removing%20PVC%20.%2B%20from%20claims%20in%20progress%5C%22%22%7D,%7B%22mode%22:%22Logs%22%7D,%7B%22ui%22:%5Btrue,true,true,%22numbers%22%5D%7D%5D',
          type='link',
        );

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
        statPanel.new(
          title=title,
          datasource='$alertmanager',
          graphMode='none',
          colorMode='background',
        )
        .addTarget({ type: 'single', expr: expr });

      local criticalPanel =
        alertPanel(
          title='Critical',
          expr='ALERTS{alertname!="Watchdog", severity="critical", alertgroup=~"%s"}' % $._config.prometheusRules.alertGroupCluster,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertOverview, $._config.prometheusRules.alertGroupCluster, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.commonThresholds.criticalPanel));

      local warningPanel =
        alertPanel(
          title='Warning',
          expr='ALERTS{alertname!="Watchdog", severity="warning", alertgroup="%s"}' % $._config.prometheusRules.alertGroupCluster,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&var-alertgroup=%s&%s' % [$._config.grafanaDashboards.ids.alertOverview, $._config.prometheusRules.alertGroupCluster, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.commonThresholds.warningPanel));

      local percentStatPanel(title, expr) =
        statPanel.new(
          title=title,
          datasource='$datasource',
          colorMode='background',
          unit='percent',
        )
        .addTarget(prometheus.target(expr));

      local nodesHealthPanel =
        percentStatPanel(
          title='Nodes Health',
          expr='avg(%s)' % $._config.templates.nodeHealth.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.nodeOverview, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.nodeHealth.thresholds));

      local runningPodsPanel =
        percentStatPanel(
          title='Running Pods',
          expr=$._config.templates.runningPods.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.podOverview, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.runningPods.thresholds));

      local runningStatefulSetsPanel =
        percentStatPanel(
          title='Running StatefulSets',
          expr=$._config.templates.runningStatefulSets.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.statefulSetOverview, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.runningStatefulSets.thresholds));

      local daemonSetsHealthPanel =
        percentStatPanel(
          title='DaemonSets Health',
          expr=$._config.templates.daemonSetsHealth.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.daemonSetOverview, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.daemonSetsHealth.thresholds));

      local pvcBoundPanel =
        percentStatPanel(
          title='PVC Bound',
          expr='%s OR on() vector(-1)' % $._config.templates.pvcBound.expr,
        )
        .addMapping({ text: '-', type: 1, value: -1 })
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.pvcOverview, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThreshold({ color: $._config.grafanaDashboards.color.black, value: -1 })
        .addThresholds($.grafanaThresholds($._config.templates.pvcBound.thresholds, 0));

      local deploymentsHealthPanel =
        percentStatPanel(
          title='Deployments Health',
          expr=$._config.templates.deploymentsHealth.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.deploymentOverview, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.deploymentsHealth.thresholds));

      local runningContainersPanel =
        percentStatPanel(
          title='Running Containers',
          expr=$._config.templates.runningContainers.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.containerOverview, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.runningContainers.thresholds));

      local succeededJobsPanel =
        percentStatPanel(
          title='Succeeded Jobs',
          expr='%s OR on() vector(-1)' % $._config.templates.succeededJobs.expr,
        )
        .addMapping({ text: '-', type: 1, value: -1 })
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.jobOverview, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThreshold({ color: $._config.grafanaDashboards.color.black, value: -1 })
        .addThresholds($.grafanaThresholds($._config.templates.succeededJobs.thresholds, 0));

      local mostUtilizedPVCPanel =
        percentStatPanel(
          title='Most Utilized PVC',
          expr='%s OR on() vector(-1)' % $._config.templates.mostUtilizedPVC.expr,
        )
        .addMapping({ text: '-', type: 1, value: -1 })
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.pvcOverview, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThreshold({ color: $._config.grafanaDashboards.color.black, value: -1 })
        .addThresholds($.grafanaThresholds($._config.templates.mostUtilizedPVC.thresholds, 0));

      local apiServerPanel =
        percentStatPanel(
          title='API Server',
          expr=$._config.templates.apiServerHealth.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.apiServer, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.apiServerHealth.thresholds));

      local controllerManagerPanel =
        percentStatPanel(
          title='Controller Manager',
          expr=$._config.templates.controllerManagerHealth.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.controllerManager, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.controllerManagerHealth.thresholds));

      local etcdPanel =
        percentStatPanel(
          title='Etcd',
          expr=$._config.templates.etcdHealth.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.etcd, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.etcdHealth.thresholds));

      local kubeletPanel =
        percentStatPanel(
          title='Kubelet',
          expr=$._config.templates.kubeletHealth.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.kubelet, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.kubeletHealth.thresholds));

      local proxyPanel =
        percentStatPanel(
          title='Proxy',
          expr=$._config.templates.proxyHealth.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.proxy, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.proxyHealth.thresholds));

      local schedulerPanel =
        percentStatPanel(
          title='Scheduler',
          expr=$._config.templates.schedulerHealth.expr,
        )
        .addDataLink({ title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.scheduler, $._config.grafanaDashboards.dataLinkCommonArgs] })
        .addThresholds($.grafanaThresholds($._config.templates.schedulerHealth.thresholds));

      local overallUtilizationCPUPanel =
        percentStatPanel(
          title='Overall Utilization',
          expr='avg(%s)' % $._config.templates.nodeCpuUtilization.expr % { job: 'job=~"$job"' },
        )
        .addThresholds($.grafanaThresholds($._config.templates.nodeCpuUtilization.thresholds))
        .addDataLinks(
          [
            { title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$._config.grafanaDashboards.ids.cpuOverview, $._config.grafanaDashboards.dataLinkCommonArgs] },
            { title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.cpuNamespaceOverview, $._config.grafanaDashboards.dataLinkCommonArgs] },
          ]
        );

      local mostUtilizedNodeCPUPanel =
        percentStatPanel(
          title='Most Utilized Node',
          expr='max(%s)' % $._config.templates.nodeCpuUtilization.expr % { job: 'job=~"$job"' },
        )
        .addThresholds($.grafanaThresholds($._config.templates.nodeCpuUtilization.thresholds))
        .addDataLinks(
          [
            { title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$._config.grafanaDashboards.ids.cpuOverview, $._config.grafanaDashboards.dataLinkCommonArgs] },
            { title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.cpuNamespaceOverview, $._config.grafanaDashboards.dataLinkCommonArgs] },
          ]
        );

      local overallUtilizationRAMPanel =
        percentStatPanel(
          title='Overall Utilization',
          expr='avg(%s)' % $._config.templates.nodeRamUtilization.expr % { job: 'job=~"$job"' },
        )
        { description: 'The percentage of the memory utilization is calculated by:\n```\n1 - (<memory available>/<memory total>)\n```' }
        .addThresholds($.grafanaThresholds($._config.templates.nodeRamUtilization.thresholds))
        .addDataLinks(
          [
            { title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$._config.grafanaDashboards.ids.memoryOverview, $._config.grafanaDashboards.dataLinkCommonArgs] },
            { title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.memoryNamespaceOverview, $._config.grafanaDashboards.dataLinkCommonArgs] },
          ]
        );

      local mostUtilizedNodeRAMPanel =
        percentStatPanel(
          title='Most Utilized Node',
          expr='max(%s)' % $._config.templates.nodeRamUtilization.expr % { job: 'job=~"$job"' },
        )
        { description: 'The percentage of the memory utilization is calculated by:\n```\n1 - (<memory available>/<memory total>)\n```' }
        .addThresholds($.grafanaThresholds($._config.templates.nodeRamUtilization.thresholds))
        .addDataLinks(
          [
            { title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$._config.grafanaDashboards.ids.memoryOverview, $._config.grafanaDashboards.dataLinkCommonArgs] },
            { title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.memoryNamespaceOverview, $._config.grafanaDashboards.dataLinkCommonArgs] },
          ]
        );

      local overallUtilizationDiskPanel =
        percentStatPanel(
          title='Overall Utilization',
          expr='avg(%s)' % $._config.templates.nodeDiskUtilization.expr % { job: 'job=~"$job"' },
        )
        { description: 'The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition.' }
        .addThresholds($.grafanaThresholds($._config.templates.nodeDiskUtilization.thresholds))
        .addDataLink({ title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$._config.grafanaDashboards.ids.diskOverview, $._config.grafanaDashboards.dataLinkCommonArgs] });

      local mostUtilizedNodeDiskPanel =
        percentStatPanel(
          title='Most Utilized Node',
          expr='max(%s)' % $._config.templates.nodeDiskUtilization.expr % { job: 'job=~"$job"' },
        )
        { description: 'The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition.' }
        .addThresholds($.grafanaThresholds($._config.templates.nodeDiskUtilization.thresholds))
        .addDataLink({ title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$._config.grafanaDashboards.ids.diskOverview, $._config.grafanaDashboards.dataLinkCommonArgs] });

      local networkErrorsPanel =
        percentStatPanel(
          title='Errors',
          expr='sum(%s)' % $._config.templates.nodeNetworkErrors.expr % { job: 'job=~"$job"' },
        )
        { fieldConfig: { defaults: { unit: 'pps' } } }
        .addThresholds($.grafanaThresholds($._config.templates.nodeNetworkErrors.thresholds))
        .addDataLinks(
          [
            { title: 'System Overview', url: '/d/%s?%s&var-instance=All' % [$._config.grafanaDashboards.ids.networkOverview, $._config.grafanaDashboards.dataLinkCommonArgs] },
            { title: 'K8s Overview', url: '/d/%s?%s' % [$._config.grafanaDashboards.ids.networkNamespaceOverview, $._config.grafanaDashboards.dataLinkCommonArgs] },
          ]
        );

      local valueStatPanel(title, expr, unit='none') =
        statPanel.new(
          title=title,
          datasource='$datasource',
          graphMode='none',
          unit=unit,
        )
        .addTarget(prometheus.target(expr))
        .addThreshold({ color: $._config.grafanaDashboards.color.white, value: null });

      local usedCoresPanel =
        valueStatPanel(
          title='Used Cores',
          expr='(1 - (avg(irate(node_cpu_seconds_total{cluster=~"$cluster", job=~"$job", mode="idle"}[5m])))) * count(node_cpu_seconds_total{cluster=~"$cluster", job=~"$job", mode="system"})',
        );

      local totalCoresPanel =
        valueStatPanel(
          title='Total Cores',
          expr='count(node_cpu_seconds_total{cluster=~"$cluster", job=~"$job", mode="system"})',
        );

      local usedRAMPanel =
        valueStatPanel(
          title='Used',
          expr='sum(node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}) * (((1 - sum(node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"$job"}) / sum(node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}))))',
          unit='bytes',
        );

      local totalRAMPanel =
        valueStatPanel(
          title='Total',
          expr='sum(node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}) ',
          unit='bytes',
        );

      local usedDiskPanel =
        valueStatPanel(
          title='Used',
          expr='sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) * ((\navg(\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device)) /\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device) +\nsum(node_filesystem_avail_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device))\n)))',
          unit='bytes',
        );

      local totalDiskPanel =
        valueStatPanel(
          title='Total',
          expr='sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"})',
          unit='bytes',
        );

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

      local clusterTemplate =
        template.new(
          name='cluster',
          label='Cluster',
          datasource='$datasource',
          query='label_values(kube_node_info, cluster)',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      local jobTemplate =
        template.new(
          name='job',
          query='label_values(node_exporter_build_info{cluster=~"$cluster", pod!~""}, job)',
          label='Job',
          datasource='$datasource',
          sort=$._config.grafanaDashboards.templateSort,
          refresh=$._config.grafanaDashboards.templateRefresh,
          hide='variable',
        );

      local datasourceLogsTemplate =
        template.datasource(
          name='datasource_logs',
          label='Logs datasource',
          query='loki',
          current=null,
          hide='variable',
        );

      local isAppMonitoring =
        std.length($._config.appMonitoring.apps) > 0 && $._config.appMonitoring.enabled;

      local isHostMonitoring =
        std.length([$._config.hostMonitoring.hosts]) > 0 && $._config.hostMonitoring.enabled;

      local links = (if isAppMonitoring then [appMonitoringLink] else []) +
                    (if isHostMonitoring then [hostMonitoringLink] else []) +
                    [
                      containerLink,
                    ]
                    + (if $._config.grafanaDashboards.isLoki then [explorerLink] else [])
                    + [
                      dNationLink,
                    ];

      local templates = [
                          datasourceTemplate,
                          alertManagerTemplate,
                          clusterTemplate,
                          jobTemplate,
                        ]
                        + if $._config.grafanaDashboards.isLoki then [datasourceLogsTemplate] else [];

      dashboard.new(
        'Kubernetes Monitoring',
        editable=$._config.grafanaDashboards.editable,
        graphTooltip=$._config.grafanaDashboards.tooltip,
        refresh=$._config.grafanaDashboards.refresh,
        time_from=$._config.grafanaDashboards.time_from,
        tags=$._config.grafanaDashboards.tags.k8sMonitoring,
        uid=$._config.grafanaDashboards.ids.k8sMonitoring,
      )
      .addLinks(links)
      .addTemplates(templates)
      .addPanels(
        [
          row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
          warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
          row.new('Overview') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
          nodesHealthPanel { gridPos: { x: 0, y: 5, w: 6, h: 3 } },
          runningStatefulSetsPanel { gridPos: { x: 6, y: 5, w: 6, h: 3 } },
          runningPodsPanel { gridPos: { x: 12, y: 5, w: 6, h: 3 } },
          succeededJobsPanel { gridPos: { x: 18, y: 5, w: 6, h: 3 } },
          deploymentsHealthPanel { gridPos: { x: 0, y: 8, w: 6, h: 3 } },
          daemonSetsHealthPanel { gridPos: { x: 6, y: 8, w: 6, h: 3 } },
          runningContainersPanel { gridPos: { x: 12, y: 8, w: 6, h: 3 } },
          pvcBoundPanel { gridPos: { x: 18, y: 8, w: 3, h: 3 } },
          mostUtilizedPVCPanel { gridPos: { x: 21, y: 8, w: 3, h: 3 } },
          row.new('Control Plane Components Health') { gridPos: { x: 0, y: 11, w: 24, h: 1 } },
          apiServerPanel { gridPos: { x: 0, y: 12, w: 4, h: 3 } },
          controllerManagerPanel { gridPos: { x: 4, y: 12, w: 4, h: 3 } },
          etcdPanel { gridPos: { x: 8, y: 12, w: 4, h: 3 } },
          kubeletPanel { gridPos: { x: 12, y: 12, w: 4, h: 3 } },
          proxyPanel { gridPos: { x: 16, y: 12, w: 4, h: 3 } },
          schedulerPanel { gridPos: { x: 20, y: 12, w: 4, h: 3 } },
          row.new('Node Metrics (including Master)') { gridPos: { x: 0, y: 15, w: 24, h: 1 } },
          text.new('CPU') { gridPos: { x: 0, y: 16, w: 6, h: 1 } },
          text.new('RAM') { gridPos: { x: 6, y: 16, w: 6, h: 1 } },
          text.new('Disk') { gridPos: { x: 12, y: 16, w: 6, h: 1 } },
          text.new('Network') { gridPos: { x: 18, y: 16, w: 6, h: 1 } },
          overallUtilizationCPUPanel { gridPos: { x: 0, y: 17, w: 3, h: 3 } },
          mostUtilizedNodeCPUPanel { gridPos: { x: 3, y: 17, w: 3, h: 3 } },
          overallUtilizationRAMPanel { gridPos: { x: 6, y: 17, w: 3, h: 3 } },
          mostUtilizedNodeRAMPanel { gridPos: { x: 9, y: 17, w: 3, h: 3 } },
          overallUtilizationDiskPanel { gridPos: { x: 12, y: 17, w: 3, h: 3 } },
          mostUtilizedNodeDiskPanel { gridPos: { x: 15, y: 17, w: 3, h: 3 } },
          networkErrorsPanel { gridPos: { x: 18, y: 17, w: 6, h: 3 } },
          usedCoresPanel { gridPos: { x: 0, y: 20, w: 3, h: 2 } },
          totalCoresPanel { gridPos: { x: 3, y: 20, w: 3, h: 2 } },
          usedRAMPanel { gridPos: { x: 6, y: 20, w: 3, h: 2 } },
          totalRAMPanel { gridPos: { x: 9, y: 20, w: 3, h: 2 } },
          usedDiskPanel { gridPos: { x: 12, y: 20, w: 3, h: 2 } },
          totalDiskPanel { gridPos: { x: 15, y: 20, w: 3, h: 2 } },
        ]
      ),
  },
}
