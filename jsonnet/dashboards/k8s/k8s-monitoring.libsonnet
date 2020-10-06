/*
  Copyright 2020 The K8s-m8g Authors. All Rights Reserved.
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
    'k8s-monitoring.json':
      local experimentalLink =
        link.dashboards(
          asDropdown=false,
          icon='external link',
          tags=['view'],
          title='Logs (Experimental)',
          type='link',
          url='/d/%s' % $._config.dashboardIDs.logs,
        );

      local explorerLink =
        link.dashboards(
          icon='external link',
          tags=[],
          title='Logs Explorer',
          type='link',
          url='/explore?orgId=1&left=%5B%22now-7d%22,%22now%22,%22k8s-h-01-logs%22,%7B%22expr%22:%22%7Bnamespace%3D%5C%22kube-system%5C%22,%20stream%3D%5C%22stderr%5C%22%7D%20%7C~%20%5C%22(%3Fi)error%5C%22%20!~%20%5C%22Final%20error%20received,%20removing%20PVC%20.%2B%20from%20claims%20in%20progress%5C%22%22%7D,%7B%22mode%22:%22Logs%22%7D,%7B%22ui%22:%5Btrue,true,true,%22numbers%22%5D%7D%5D',
        );

      local dNationLink =
        link.dashboards(
          icon='cloud',
          targetBlank=true,
          tags=[],
          title='dNation - Making Cloud Easy',
          type='link',
          url='https://www.dnation.tech/',
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
          expr='ALERTS{alertname!="Watchdog", severity="critical"}',
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=critical&%s' % [$._config.dashboardIDs.alertOverview, $._config.dashboardCommon.dataLinkCommonArgs] })
        .addThresholds(
          [
            { color: $._config.dashboardCommon.color.green, value: null },
            { color: $._config.dashboardCommon.color.red, value: 1 },
          ]
        );

      local warningPanel =
        alertPanel(
          title='Warning',
          expr='ALERTS{alertname!="Watchdog", severity="warning"}',
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?var-alertmanager=$alertmanager&var-severity=warning&%s' % [$._config.dashboardIDs.alertOverview, $._config.dashboardCommon.dataLinkCommonArgs] })
        .addThresholds(
          [
            { color: $._config.dashboardCommon.color.green, value: null },
            { color: $._config.dashboardCommon.color.orange, value: 1 },
          ]
        );

      local overviewThresholds =
        [
          { color: $._config.dashboardCommon.color.red, value: 0 },
          { color: $._config.dashboardCommon.color.orange, value: 95 },
          { color: $._config.dashboardCommon.color.green, value: 99 },
        ];

      local percentStatPanel(title, expr) =
        statPanel.new(
          title=title,
          datasource='$datasource',
          colorMode='background',
          unit='percent',
        )
        .addTarget(prometheus.target(expr=expr));

      local nodesHealthPanel =
        percentStatPanel(
          title='Nodes Health',
          expr='sum(kube_node_info{cluster=~"$cluster"}) / (sum(kube_node_info{cluster=~"$cluster"}) + sum(kube_node_spec_unschedulable{cluster=~"$cluster"}) + sum(kube_node_status_condition{cluster=~"$cluster", condition="DiskPressure", status="true"}) + sum(kube_node_status_condition{cluster=~"$cluster", condition="MemoryPressure", status="true"})) * 100',
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.nodeOverview, $._config.dashboardCommon.dataLinkCommonArgs] })
        .addThresholds(overviewThresholds);

      local runningPodsPanel =
        percentStatPanel(
          title='Running PODs',
          expr='sum(kube_pod_status_phase{cluster=~"$cluster", phase="Running"}) / (sum(kube_pod_status_phase{cluster=~"$cluster", phase="Running"}) + sum(kube_pod_status_phase{cluster=~"$cluster", phase="Pending"}) + sum(kube_pod_status_phase{cluster=~"$cluster", phase="Failed"}) + sum(kube_pod_status_phase{cluster=~"$cluster", phase="Unknown"})) * 100',
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.podOverview, $._config.dashboardCommon.dataLinkCommonArgs] })
        .addThresholds(overviewThresholds);

      local runningStatefulSetsPanel =
        percentStatPanel(
          title='Running Stateful Sets',
          expr='sum(kube_statefulset_status_replicas_current{cluster=~"$cluster", %(stateMetrics)s}) / sum(kube_statefulset_replicas{cluster=~"$cluster", %(stateMetrics)s}) * 100' % $._config.dashboardSelectors,
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.statefulSetOverview, $._config.dashboardCommon.dataLinkCommonArgs] })
        .addThresholds(overviewThresholds);

      local pvcBoundPanel =
        percentStatPanel(
          title='PVC Bound',
          expr='sum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", phase="Bound"}) / (\nsum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", phase="Bound"}) + sum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", phase="Pending"}) +\nsum(kube_persistentvolumeclaim_status_phase{cluster=~"$cluster", phase="Lost"})\n) * 100 OR on() vector(-1)',
        )
        .addMapping({ text: '-', type: 1, value: -1 })
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.pvcOverview, $._config.dashboardCommon.dataLinkCommonArgs] })
        .addThreshold({ color: $._config.dashboardCommon.color.black, value: -1 })
        .addThresholds(overviewThresholds);

      local deploymentsHealthPanel =
        percentStatPanel(
          title='Deployments Health',
          expr='sum(kube_deployment_status_replicas_updated{cluster=~"$cluster"}) / (sum(kube_deployment_status_replicas{cluster=~"$cluster"}) + sum(kube_deployment_status_replicas_unavailable{cluster=~"$cluster"})) * 100',
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.deploymentOverview, $._config.dashboardCommon.dataLinkCommonArgs] })
        .addThresholds(overviewThresholds);

      local runningContainersPanel =
        percentStatPanel(
          title='Running Containers',
          expr='sum(kube_pod_container_status_running{cluster=~"$cluster"}) / (sum(kube_pod_container_status_running{cluster=~"$cluster"}) + sum(kube_pod_container_status_terminated_reason{cluster=~"$cluster", reason!="Completed"}) + sum(kube_pod_container_status_waiting{cluster=~"$cluster"})) * 100',
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.containerOverview, $._config.dashboardCommon.dataLinkCommonArgs] })
        .addThresholds(overviewThresholds);

      local succeededJobsPanel =
        percentStatPanel(
          title='Succeeded Jobs',
          expr='sum(kube_job_status_succeeded{cluster=~"$cluster"}) / (sum(kube_job_status_succeeded{cluster=~"$cluster"}) + sum(kube_job_status_failed{cluster=~"$cluster"})) * 100 OR on() vector(-1)',
        )
        .addMapping({ text: '-', type: 1, value: -1 })
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.jobOverview, $._config.dashboardCommon.dataLinkCommonArgs] })
        .addThreshold({ color: $._config.dashboardCommon.color.black, value: -1 })
        .addThresholds(overviewThresholds);

      local mostUtilizedPVCPanel =
        percentStatPanel(
          title='Most Utilized PVC',
          expr='max(sum(\n  ((kubelet_volume_stats_capacity_bytes{cluster=~"$cluster"} - kubelet_volume_stats_available_bytes{cluster=~"$cluster"}) / \n  kubelet_volume_stats_capacity_bytes{cluster=~"$cluster"}) * 100\n) by (persistentvolumeclaim)) OR on() vector(-1)',
        )
        .addMapping({ text: '-', type: 1, value: -1 })
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.pvcOverview, $._config.dashboardCommon.dataLinkCommonArgs] })
        .addThresholds(
          [
            { color: $._config.dashboardCommon.color.black, value: -1 },
            { color: $._config.dashboardCommon.color.green, value: 0 },
            { color: $._config.dashboardCommon.color.orange, value: 85 },
            { color: $._config.dashboardCommon.color.red, value: 97 },
          ]
        );

      local controlPlaneComponentsThresholds =
        [
          { color: $._config.dashboardCommon.color.red, value: null },
          { color: $._config.dashboardCommon.color.green, value: 1 },
        ];

      local textMappings =
        [
          { from: 1, to: 1, type: 2, text: 'Up' },
          { from: 0, to: 1, type: 2, text: 'Down' },
        ];

      local textStatPanel(title, expr) =
        percentStatPanel(title=title, expr=expr)
        { fieldConfig: { defaults: { unit: 'short' } } }
        .addMappings(textMappings)
        .addThresholds(controlPlaneComponentsThresholds);

      local apiServerPanel =
        textStatPanel(
          title='API Server',
          expr='sum(up{cluster=~"$cluster", %(apiServer)s}) / count(up{cluster=~"$cluster", %(apiServer)s})' % $._config.dashboardSelectors,
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.apiServer, $._config.dashboardCommon.dataLinkCommonArgs] });

      local controllerManagerPanel =
        textStatPanel(
          title='Controller Manager',
          expr='sum(up{cluster=~"$cluster", %(controllerManager)s}) / count(up{cluster=~"$cluster", %(controllerManager)s})' % $._config.dashboardSelectors,
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.controllerManager, $._config.dashboardCommon.dataLinkCommonArgs] });

      local etcdPanel =
        textStatPanel(
          title='Etcd',
          expr='sum(up{cluster=~"$cluster", %(etcd)s}) / count(up{cluster=~"$cluster", %(etcd)s})' % $._config.dashboardSelectors,
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.etcd, $._config.dashboardCommon.dataLinkCommonArgs] });

      local kubeletPanel =
        textStatPanel(
          title='Kubelet',
          expr='sum(up{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics"}) / count(up{cluster=~"$cluster", %(kubelet)s, metrics_path="/metrics"})' % $._config.dashboardSelectors,
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.kubelet, $._config.dashboardCommon.dataLinkCommonArgs] });

      local proxyPanel =
        textStatPanel(
          title='Proxy',
          expr='sum(up{cluster=~"$cluster", %(proxy)s}) / count(up{cluster=~"$cluster", %(proxy)s})' % $._config.dashboardSelectors,
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.proxy, $._config.dashboardCommon.dataLinkCommonArgs] });

      local schedulerPanel =
        textStatPanel(
          title='Scheduler',
          expr='sum(up{cluster=~"$cluster", %(scheduler)s}) / count(up{cluster=~"$cluster", %(scheduler)s})' % $._config.dashboardSelectors,
        )
        .addDataLink({ title: 'Detail', url: '/d/%s?%s' % [$._config.dashboardIDs.scheduler, $._config.dashboardCommon.dataLinkCommonArgs] });

      local nodeMetricsThresholds =
        [
          { color: $._config.dashboardCommon.color.green, value: null },
          { color: $._config.dashboardCommon.color.orange, value: 75 },
          { color: $._config.dashboardCommon.color.red, value: 90 },
        ];

      local overallUtilizationCPUPanel =
        percentStatPanel(
          title='Overall Utilization',
          expr='round((1 - (avg(irate(node_cpu_seconds_total{cluster=~"$cluster", job=~"$job", mode="idle"}[5m])))) * 100)',
        )
        .addThresholds(nodeMetricsThresholds)
        .addDataLinks(
          [
            { title: 'per Node', url: '/d/%s?%s&var-instance=All' % [$._config.dashboardIDs.cpuOverview, $._config.dashboardCommon.dataLinkCommonArgs] },
            { title: 'per Namespace', url: '/d/bEN1iiMGz?%s' % [$._config.dashboardCommon.dataLinkCommonArgs] },
          ]
        );

      local mostUtilizedNodeCPUPanel =
        percentStatPanel(
          title='Most Utilized Node',
          expr='round(max((1 - (avg by (instance) (irate(node_cpu_seconds_total{cluster=~"$cluster", job=~"$job", mode="idle"}[5m])))) * 100))',
        )
        .addThresholds(nodeMetricsThresholds)
        .addDataLinks(
          [
            { title: 'per Node', url: '/d/%s?%s&var-instance=All' % [$._config.dashboardIDs.cpuOverview, $._config.dashboardCommon.dataLinkCommonArgs] },
            { title: 'per Namespace', url: '/d/bEN1iiMGz?%s' % [$._config.dashboardCommon.dataLinkCommonArgs] },
          ]
        );

      local overallUtilizationRAMPanel =
        percentStatPanel(
          title='Overall Utilization',
          expr='round((1 - sum(node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"$job"}) / sum(node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"})) * 100)',
        )
        { description: 'The percentage of the memory utilization is calculated by:\n```\n1 - (<memory available>/<memory total>)\n```' }
        .addThresholds(nodeMetricsThresholds)
        .addDataLinks(
          [
            { title: 'per Node', url: '/d/%s?%s&var-instance=All' % [$._config.dashboardIDs.memoryOverview, $._config.dashboardCommon.dataLinkCommonArgs] },
            { title: 'per Namespace', url: '/d/%s?%s' % [$._config.dashboardIDs.memoryNamespaceOverview, $._config.dashboardCommon.dataLinkCommonArgs] },
          ]
        );

      local mostUtilizedNodeRAMPanel =
        percentStatPanel(
          title='Most Utilized Node',
          expr='round(max((1 - sum(node_memory_MemAvailable_bytes{cluster=~"$cluster", job=~"$job"}) by (instance) / sum(node_memory_MemTotal_bytes{cluster=~"$cluster", job=~"$job"}) by (instance)) * 100))',
        )
        { description: 'The percentage of the memory utilization is calculated by:\n```\n1 - (<memory available>/<memory total>)\n```' }
        .addThresholds(nodeMetricsThresholds)
        .addDataLinks(
          [
            { title: 'per Node', url: '/d/%s?%s&var-instance=All' % [$._config.dashboardIDs.memoryOverview, $._config.dashboardCommon.dataLinkCommonArgs] },
            { title: 'per Namespace', url: '/d/%s?%s' % [$._config.dashboardIDs.memoryNamespaceOverview, $._config.dashboardCommon.dataLinkCommonArgs] },
          ]
        );

      local overallUtilizationDiskPanel =
        percentStatPanel(
          title='Overall Utilization',
          expr='round(\navg(\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device)) /\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device) +\nsum(node_filesystem_avail_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (device))\n * 100\n))',
        )
        { description: 'The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition.' }
        .addThresholds(nodeMetricsThresholds)
        .addDataLink({ title: 'per Node', url: '/d/%s?%s&var-instance=All' % [$._config.dashboardIDs.diskOverview, $._config.dashboardCommon.dataLinkCommonArgs] });

      local mostUtilizedNodeDiskPanel =
        percentStatPanel(
          title='Most Utilized Node',
          expr='round(\nmax(\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device)) /\n(sum(node_filesystem_size_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device) - sum(node_filesystem_free_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device) +\nsum(node_filesystem_avail_bytes{cluster=~"$cluster", job=~"$job", device!="rootfs"}) by (instance, device))\n * 100\n))',
        )
        { description: 'The percentage of the disk utilization is calculated using the fraction:\n```\n<space used>/(<space used> + <space free>)\n```\nThe value of <space free> is reduced by  5% of the available disk capacity, because   \nthe file system marks 5% of the available disk capacity as reserved. \nIf less than 5% is free, using the remaining reserved space requires root privileges.\nAny non-privileged users and processes are unable to write new data to the partition.' }
        .addThresholds(nodeMetricsThresholds)
        .addDataLink({ title: 'per Node', url: '/d/%s?%s&var-instance=All' % [$._config.dashboardIDs.diskOverview, $._config.dashboardCommon.dataLinkCommonArgs] });

      local networkErrorsPanel =
        percentStatPanel(
          title='Errors',
          expr='sum(rate(node_network_transmit_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m])) + \nsum(rate(node_network_receive_errs_total{cluster=~"$cluster", job=~"$job", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]))',
        )
        { fieldConfig: { defaults: { unit: 'none' } } }
        .addThresholds(
          [
            { color: $._config.dashboardCommon.color.green, value: null },
            { color: $._config.dashboardCommon.color.orange, value: 10 },
            { color: $._config.dashboardCommon.color.red, value: 15 },
          ]
        )
        .addDataLinks(
          [
            { title: 'per Node', url: '/d/%s?%s&var-instance=All' % [$._config.dashboardIDs.networkOverview, $._config.dashboardCommon.dataLinkCommonArgs] },
            { title: 'per Namespace', url: '/d/%s?%s' % [$._config.dashboardIDs.networkNamespaceOverview, $._config.dashboardCommon.dataLinkCommonArgs] },
          ]
        );

      local valueStatPanel(title, expr, unit='none') =
        statPanel.new(
          title=title,
          datasource='$datasource',
          graphMode='none',
          unit=unit,
        )
        .addTarget(prometheus.target(expr=expr))
        .addThreshold({ color: $._config.dashboardCommon.color.white, value: null });

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
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      local jobTemplate =
        template.new(
          name='job',
          query='label_values(node_exporter_build_info{cluster=~"$cluster", pod!~""}, job)',
          label='Job',
          datasource='$datasource',
          sort=$._config.dashboardCommon.templateSort,
          refresh=$._config.dashboardCommon.templateRefresh,
          hide='variable',
        );

      dashboard.new(
        'Kubernetes Green/Red Monitoring',
        description='Green/Red Kubernetes Monitoring',
        editable=$._config.dashboardCommon.editable,
        graphTooltip=$._config.dashboardCommon.tooltip,
        refresh=$._config.dashboardCommon.refresh,
        time_from=$._config.dashboardCommon.time_from,
        tags=$._config.dashboardCommon.tags.k8sMonitoring,
        uid=$._config.dashboardIDs.k8sMonitoring,
      )
      .addLink(experimentalLink)
      .addLink(explorerLink)
      .addLink(dNationLink)
      .addTemplates([datasourceTemplate, alertManagerTemplate, clusterTemplate, jobTemplate])
      .addPanels(
        [
          row.new('Alerts') { gridPos: { x: 0, y: 0, w: 24, h: 1 } },
          criticalPanel { gridPos: { x: 0, y: 1, w: 12, h: 3 } },
          warningPanel { gridPos: { x: 12, y: 1, w: 12, h: 3 } },
          row.new('Overview') { gridPos: { x: 0, y: 4, w: 24, h: 1 } },
          nodesHealthPanel { gridPos: { x: 0, y: 5, w: 6, h: 3 } },
          runningPodsPanel { gridPos: { x: 6, y: 5, w: 6, h: 3 } },
          runningStatefulSetsPanel { gridPos: { x: 12, y: 5, w: 6, h: 3 } },
          pvcBoundPanel { gridPos: { x: 18, y: 5, w: 6, h: 3 } },
          deploymentsHealthPanel { gridPos: { x: 0, y: 8, w: 6, h: 3 } },
          runningContainersPanel { gridPos: { x: 6, y: 8, w: 6, h: 3 } },
          succeededJobsPanel { gridPos: { x: 12, y: 8, w: 6, h: 3 } },
          mostUtilizedPVCPanel { gridPos: { x: 18, y: 8, w: 6, h: 3 } },
          row.new('Control Plane Components') { gridPos: { x: 0, y: 11, w: 24, h: 1 } },
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
