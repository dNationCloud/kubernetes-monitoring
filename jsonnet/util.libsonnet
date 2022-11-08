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

{

  local utils = self,

  vmJobs::
    if self.isClusterMonitoring() then
      [
        vm.jobName
        for cluster in $._config.clusterMonitoring.clusters
        if (std.objectHas(cluster, 'vms') && std.length(cluster.vms) > 0)
        for vm in cluster.vms
      ]
    else
      [],

  hostJobs::
    if self.isHostMonitoring() then
      [
        host.jobName
        for host in $._config.hostMonitoring.hosts
      ]
    else
      [],

  zipWithIndex(arr)::
    /**
     * Enumarate array elements.
     *
     * @param arrays The input array.
     * @return indexed dict in form: { index:<array index>, item:<array element> }.
    */
    std.makeArray(std.length(arr), function(i) { index: i, item: arr[i] }),

  sumArr(arr)::
    /**
     * Compute sum of array elements.
     *
     * @param arrays The input array.
     * @return sum as number.
     */
    std.foldl(function(x, y) x + y, arr, 0),

  getNextIndex(arrays)::
    /**
     * Compute index (starting from 1) which would have new element
     * in array made by concatenating input arrays.
     *
     * @param arrays The input array of arrays.
     * @return next index as number.
     */
    utils.sumArr([std.length(arr) for arr in arrays]) + 1,

  isMember(arr, x)::
    /**
     * Return true, if x is in arr.
     * This is exact copy of std.member, which has problem linter with. (bug)
     *
     * @param x
     * @return arr
     */
    if std.isArray(arr) then
      std.count(arr, x) > 0
    else if std.isString(arr) then
      std.length(std.findSubstr(x, arr)) > 0
    else error 'std.member first argument must be an array or a string',

  getCustomUid(nameStrings)::
    //uid in grafana can be only 40 characters long
    std.md5(std.join('', std.map(std.asciiLower, nameStrings))),

  getCustomName(nameStrings)::
    std.join(' ', nameStrings),

  isClusterMonitoring()::
    $._config.clusterMonitoring.enabled && std.length($._config.clusterMonitoring.clusters) > 0,

  isHostMonitoring()::
    $._config.hostMonitoring.enabled && std.length($._config.hostMonitoring.hosts) > 0,

  isMultiClusterMonitoring()::
    $._config.clusterMonitoring.enabled && std.length($._config.clusterMonitoring.clusters) > 1,

  dashboardTemplateMapping():: {
    /**
     * Maps dashboards to their template group. User defined templates from values.yaml are included too.
     */
    [$._config.grafanaDashboards.ids.monitoring]: $._config.templates.L0.k8s + $._config.templates.L0.host,
    [$._config.grafanaDashboards.ids.k8sMonitoring]: $._config.templates.L1.k8s,
    [$._config.grafanaDashboards.ids.containerOverview]: $._config.templates.L2.containerOverview,
    [$._config.grafanaDashboards.ids.nodeOverview]: $._config.templates.L2.nodeOverview,
    [$._config.grafanaDashboards.ids.pvcOverview]: $._config.templates.L2.pvcOverview,
    [$._config.grafanaDashboards.ids.statefulSetOverview]: $._config.templates.L2.statefulSetOverview,
    [$._config.grafanaDashboards.ids.podOverview]: $._config.templates.L2.podOverview,
    [$._config.grafanaDashboards.ids.deploymentOverview]: $._config.templates.L2.deploymentOverview,
    [$._config.grafanaDashboards.ids.daemonSetOverview]: $._config.templates.L2.daemonSetOverview,
    [$._config.grafanaDashboards.ids.jobOverview]: $._config.templates.L2.jobOverview,
    [$._config.grafanaDashboards.ids.networkOverview]: $._config.templates.L2.networkPerNode,
    [$._config.grafanaDashboards.ids.memoryOverview]: $._config.templates.L2.memoryPerNode,
    [$._config.grafanaDashboards.ids.cpuOverview]: $._config.templates.L2.cpuPerNode,
    [$._config.grafanaDashboards.ids.diskOverview]: $._config.templates.L2.diskPerNode,
    [$._config.grafanaDashboards.ids.apiServer]: utils.getControlPlaneTemplates('apiServerHealth'),
    [$._config.grafanaDashboards.ids.controllerManager]: utils.getControlPlaneTemplates('controllerManagerHealth'),
    [$._config.grafanaDashboards.ids.etcd]: utils.getControlPlaneTemplates('etcdHealth'),
    [$._config.grafanaDashboards.ids.kubelet]: utils.getControlPlaneTemplates('kubeletHealth'),
    [$._config.grafanaDashboards.ids.proxy]: utils.getControlPlaneTemplates('proxyHealth'),
    [$._config.grafanaDashboards.ids.scheduler]: utils.getControlPlaneTemplates('schedulerHealth'),
  },

  getControlPlaneTemplates(templateName):: {
    /**
     * Create object from k8s templates that belong to control plane defined by templateName.
     *
     * @param templateName Name of default control plane template.
     * @return object with templates.
     */
    [tplName]:
      $._config.templates.L1.k8s[tplName]
    for tplName in std.objectFields($._config.templates.L1.k8s)
    if tplName == templateName ||
       (std.objectHas($._config.templates.L1.k8s[tplName], 'parent') && $._config.templates.L1.k8s[tplName].parent == templateName)
  },

  getDashboardIdFromLinkTo(linkTo)::
    /**
     * Retrieve dashboard Id from template field 'linkTo', that can be dashboard Id or template name.
     *
     * @param linkTo String from linkTo array.
     * @return dashboard id.
     */
    local grafanaDashboardsIds = [$._config.grafanaDashboards.ids[f] for f in std.objectFields($._config.grafanaDashboards.ids)];
    if utils.isMember(grafanaDashboardsIds, linkTo) then
      linkTo
    else
      utils.getDashboardIdFromTemplate(linkTo),

  getDashboardTemplates(dashboardId)::
    /**
     * Retrieve templates from dashboard.
     *
     * @param dashboardId
     * @return object with templates for dashboard
     */
    local mapping = utils.dashboardTemplateMapping();
    if std.objectHas(mapping, dashboardId) then mapping[dashboardId] else null,

  getDashboardIdFromTemplate(templateName)::
    /**
     * Retrieve dashbord id, where template belongs.
     *
     * @param templateName
     * @return dashboard id.
     */
    local mapping = utils.dashboardTemplateMapping();
    local dashboardIds = [
      dashboardId
      for dashboardId in std.objectFields(mapping)
      if std.objectHas(mapping[dashboardId], templateName)
    ];
    if std.length(dashboardIds) > 0 then dashboardIds[0] else '',

  isCustomDashboard(obj, dashboardId, templateName=null)::
    /**
     * Return if dashboard is custom - has at least one custom template.
     *
     * @param obj Cluster or host.
     * @param dashboardId
     * @param templateName
     * @return boolean if dashboard is custom.
     */
    std.length(utils.getCustomTemplateNamesForDashboard(obj, dashboardId, templateName)) > 0,

  getCustomTemplateNamesForDashboard(obj, dashboardId, templateName=null)::
    /**
     * Return names of templates that are custom.
     * If templateName is not null, it means, that from each template is made separate dashboard (overview dashboards).
     *
     * @param obj Cluster or host.
     * @param dashboardId
     * @param templateName
     * @return array of template names.
     */
    local mapping = utils.dashboardTemplateMapping();
    if std.objectHas(mapping, dashboardId) then
      [
        tpl.templateName
        for tpl in utils.getTemplates(mapping[dashboardId], obj)
        if (templateName == null || tpl.templateName == templateName) &&
           utils.isCustomTemplate(obj, tpl.templateName)
      ]
    else
      [],

  getSpecificTemplates(templates, templateName):: [
    /**
     * Retrive templates and childs of templates defined by templateName.
     *
     * @param templates Array with templates.
     * @param templateName
     * @return array of templates.
     */
    tpl
    for tpl in templates
    if ((std.objectHas(tpl, 'templateName') && tpl.templateName == templateName) ||
        (std.objectHas(tpl, 'parent') && tpl.parent == templateName))
  ],

  getSpecificTemplate(templates, templateName)::
    /**
     * Retrieve only first template return by getSpecificTemplates.
     *
     * @param templates Array with templates.
     * @param templateName
     * @return template
     */
    local all = utils.getSpecificTemplates(templates, templateName);
    if std.length(all) > 0 then all[0] else null,

  getTemplateBase(template)::
    /**
     * Return template base object from _config.templates.templateBases.
     * If no base is defined, default is baseStatsTemplate.
     *
     * @param template
     * @return template base.
     */
    if std.objectHas(template, 'base') then
      if std.objectHas($._config.templates.templateBases, template.base) then
        $._config.templates.templateBases[template.base]
      else
        null
    else
      $._config.templates.templateBases.baseStatsTemplate,

  getTemplates(objTemplates, obj=null):: [
    /**
     * Merge user defined templates with defaults and cluster-specific template data.
     *
     * @param objTemplates Object with templates.
     * @param obj Cluster or host.
     * @return array with merged templates.
     */
    tpl
    for tpl in [
      local objTemplate = objTemplates[tpl] { templateName: tpl };
      local baseTemplate = utils.getTemplateBase(objTemplate);
      local parent =
        if std.objectHas(objTemplate, 'parent') then
          local parent = objTemplates[objTemplate.parent];
          local parentBase = utils.getTemplateBase(parent);
          std.mergePatch(parentBase, parent)
        else
          baseTemplate;
      local mergedTemplate = std.mergePatch(parent, objTemplate);

      if obj != null && std.objectHas(obj, 'templates') && std.objectHas(obj.templates, tpl) then
        local template = std.mergePatch(mergedTemplate, obj.templates[tpl]);
        if template.enabled then
          template
        else
          null
      else if mergedTemplate.enabled && mergedTemplate.default then
        mergedTemplate

      for tpl in std.objectFields(objTemplates)
    ]
    if std.type(tpl) == 'object'
  ],

  getTemplateAlerts(objTemplates, obj=null):: [
    /**
     * Merge user defined alerts with defaults and cluster-specific alert data.
     * Compute dashboard ids to links based on parameter linkTo. If target dashboard will be custom
     * alert name is changed too.
     *
     * @param objTemplates Object with templates.
     * @param obj Cluster or host.
     * @return array with alerts.
     */
    alert
    for alert in [
      local alert = std.mergePatch($._config.templates.templateBases.baseAlert, tpl.alert);
      if std.objectHas(tpl, 'linkTo') && std.length(tpl.linkTo) > 0 then
        local linkTo = tpl.linkTo[0];  //alert can have only 1 link, if there are multiple linkTo-s, first one is used
        local defaultDashboardId = utils.getDashboardIdFromLinkTo(linkTo);
        local customDashboardId = utils.getCustomLinkDashboardId(obj, defaultDashboardId, linkTo, tpl.templateName);
        local completeLink =
          if alert.linkGetParams != '' then '%s?%s' % [customDashboardId, alert.linkGetParams]
          else customDashboardId;
        //if alert link has changed, alert name is changed too, because its different from default alert
        local alertName =
          if customDashboardId != defaultDashboardId then
            std.join('-', [alert.name, obj.name, tpl.templateName])
          else alert.name;
        alert { name: alertName, link: completeLink }
      else
        alert { link: '' }

      for tpl in self.getTemplates(objTemplates, obj)
      if (std.objectHas(tpl, 'alert') && tpl.alert != {})
    ]
  ],

  getApps(objTemplates, obj)::
    /**
     * Retrieve apps for obj.
     *
     * @param objTemplates Object with templates.
     * @param obj Cluster or host.
     * @return array with apps.
     */
    if std.objectHas(obj, 'apps') && std.length(obj.apps) > 0 then
      [
        local templates = utils.getTemplates(objTemplates, app);
        if std.length(std.prune(templates)) == 0 then
          app { templates: [std.mergePatch($._config.templates.templateBases.baseStatsTemplate, objTemplates.genericApp) + { templateName: 'genericApp' }] }
        else
          app { templates: templates }
        for app in obj.apps
      ]
    else
      [],

  getAlertJobs(obj)::
    /**
     * Retrieve all jobs for obj.
     *
     * @param obj Cluster or host.
     * @return array with jobs.
     */
    [
      obj.jobName,
    ] +
    (if (std.objectHas(obj, 'apps') && std.length(obj.apps) > 0) then
       [
         app.jobName
         for app in obj.apps
       ]
     else []),

  hasDefaultTemplates(obj, templateGroup)::
    /**
     * Return true, if all templates from templateGroup are default for obj.
     * (i.e. there is no obj specific template (or it's parent) that is also in templateGroup)
     *
     * @param obj Cluster or host.
     * @param templateGroup Object with templates.
     * @return boolean
     */
    local templateGroupTemlates = std.objectFields(templateGroup);
    !std.objectHas(obj, 'templates') ||
    std.length(
      [
        true
        for tplName in std.objectFields(obj.templates)
        if utils.isMember(templateGroupTemlates, tplName) ||
            (std.objectHas(obj.templates[tplName], 'parent') && utils.isMember(templateGroupTemlates, obj.templates[tplName].parent))
      ]
    ) == 0,

  isAnyDefault(objs, templateGroup)::
    /**
     * Return true, if there is any obj, that has no apps, custom templates and vms.
     *
     * @param objs Array with clusters or hosts.
     * @param templateGroup Object with templates.
     * @return boolean
     */
    std.length([
      true
      for item in objs
      if !std.objectHas(item, 'apps') && utils.hasDefaultTemplates(item, templateGroup) && !std.objectHas(item, 'vms')
    ]) > 0,

  isCustomTemplate(obj, templateName)::
    /**
     * Template is custom for obj, if it appears in obj.templates field.
     *
     * @param obj Custer or host.
     * @param templateName
     * @return boolean
     */
    std.objectHas(obj, 'templates') && std.objectHas(obj.templates, templateName),

  isAnyDefaultTemplate(objs, templateName)::
    /**
     * Return true, if there is any obj that has default template specified by templateName.
     *
     * @param objs Array with clusters or hosts.
     * @param templateName
     * @return boolean
     */
    std.length([
      true
      for item in objs
      if !utils.isCustomTemplate(item, templateName)
    ]) > 0,

  getCustomLinkDashboardId(obj, defaultDashboardId, linkTo, templateName)::
    /**
     * Return dashboard id for link in templates. It changes if target dashboard will be custom.
     *
     * @param obj Custer or host.
     * @param defaultDashboardId
     * @param linkTo Item from linkTo field of template (dashboard id or template name).
     * @param templateName
     * @return string dashboard id.
     */
    local customTemplateName = if defaultDashboardId == linkTo then null else linkTo;
    if utils.isCustomDashboard(obj, defaultDashboardId, customTemplateName) then
      local targetTemplateName = if defaultDashboardId == linkTo then templateName else linkTo;
      utils.getCustomUid([defaultDashboardId, obj.name, targetTemplateName])
    else
      defaultDashboardId,

  updateDataLinksCommonArgs(datalinks, tableLink=false)::
    /**
     * If monitoring is in multi-cluster setup, we want to pass variable $cluster between dashboards.
     * If monitoring is in single-cluster setup, only '$cluster|' is passed which match everything.
     *
     * @param array Datalinks for panel.
     * @param boolean tableLink if processed datalinks are from table or panels.
     * @return array Datalinks for panel.
     */
    local clusterLabel = if utils.isMultiClusterMonitoring() then '$cluster' else '$cluster|';
    local urlField = if tableLink then 'linkUrl' else 'url';
    [
      local urlFieldValue = if tableLink then datalink.linkUrl else datalink.url;
      if std.objectHas(datalink, urlField) then
        datalink { [urlField]: std.strReplace(urlFieldValue, '$cluster|', clusterLabel) }
      else
        datalink
      for datalink in datalinks
    ],

  finalizeDataLinksUrl(obj, template)::
    /**
     * Replace placeholder {} in url with dashboard id defined by template field linkTo
     * and update dataLinkCommonArgs based on new merged config.
     *
     * @param obj Custer or host.
     * @param template
     * @return datalink object.
     */
    local datalinks = template.panel.dataLinks;
    utils.updateDataLinksCommonArgs(
      [
        if std.objectHas(template, 'linkTo') && std.length(template.linkTo) > i then
          local datalink = datalinks[i];
          local linkTo = template.linkTo[i];
          local defaultDashboardId = utils.getDashboardIdFromLinkTo(linkTo);
          local customDashboardId = utils.getCustomLinkDashboardId(obj, defaultDashboardId, linkTo, template.templateName);
          datalink { url: std.strReplace(datalink.url, '{}', customDashboardId) }
        else
          datalinks[i]
        for i in std.range(0, std.length(datalinks) - 1)
      ]
    ),

  createControlPlaneDashboard(jsonName, dashboardFunction, dashboardUid, dashboardName, templateGroup, templateName)::
    /**
     * Create custom dashboard for each cluster, if it has custom templates.
     * And/or default control plane dashboard if there is at least 1 cluster with all default templates.
     *
     * @param jsonName Default name of file with dashboard.
     * @param dashboardFunction Function that generates dashboard.
     * @param dashboardUid
     * @param dashboardName
     * @param templateGroup Object that contains templates for this dashboard. (But also other templates)
     * @param templateName Template for this specific dashboard.
     * @return object with dashboards.
     */
    if utils.isClusterMonitoring() then
      {
        [std.join('-', [jsonName, cluster.name, tpl.templateName])]:
          dashboardFunction(
            utils.getCustomUid([dashboardUid, cluster.name, tpl.templateName]),
            utils.getCustomName([dashboardName, cluster.name]),
            tpl
          ).dashboard
        for cluster in $._config.clusterMonitoring.clusters
        //tpl is placed inside array and used in for loop only so we can use it in the field name (std.join(...,tpl.templateName))
        for tpl in [utils.getSpecificTemplate(utils.getTemplates(templateGroup, cluster), templateName)]
        if utils.isCustomDashboard(cluster, dashboardUid)
      } +
      if utils.isAnyDefaultTemplate($._config.clusterMonitoring.clusters, templateName) then
        {
          [jsonName]:
            dashboardFunction(
              dashboardUid,
              dashboardName,
              utils.getSpecificTemplate(utils.getTemplates(templateGroup), templateName)
            ).dashboard,
        }
      else
        {}
    else
      {},

  createOverviewDashboards(jsonName, dashboardFunction, dashboardUid, dashboardName, templateName, rowName=null, customizableGrafanaTemplateFunction=null, grafanaTemplates=[], instancePanels=[])::
    /**
     * Create custom overview dashboards for each cluster and custom template.
     * And/or default dashboard if there is at least 1 cluster with default template.
     * (From each custom template is created separate dashboard)
     * Common function for tableOverviews (nodesHealth, runninContainers...) and polystatOverviews (cpuOverview, diskOverview...)
     *
     * @param jsonName Default name of file with dashboard.
     * @param dashboardFunction Function that generates dashboard.
     * @param dashboardUid
     * @param dashboardName
     * @param templateName Default template for this specific dashboard.
     * @param rowName Name of first row. (Only for tableOverviews)
     * @param customizableGrafanaTemplateFunction Function from grafanaTemplates, which will be used for dashboardInfo.grafanaTemplateQuery.
     * @param grafanaTemplates
     * @param instancePanels Panels repeated for instance. (Only for polystatOverviews)
     * @return object with dashboards.
     */
    local getCustomizableGrafanaTemplate(tpl, grafanaTemplateFunc) =
      if grafanaTemplateFunc != null && std.objectHas(tpl, 'dashboardInfo') && std.objectHas(tpl.dashboardInfo, 'grafanaTemplateQuery') then
        [grafanaTemplateFunc(tpl.dashboardInfo.grafanaTemplateQuery)]
      else
        [];

    local templateGroup = utils.dashboardTemplateMapping()[dashboardUid];
    if utils.isClusterMonitoring() then
      {
        [std.join('-', [jsonName, cluster.name, tpl.templateName])]:
          dashboardFunction(
            dashboardUid=utils.getCustomUid([dashboardUid, cluster.name, tpl.templateName]),
            dashboardName=utils.getCustomName([dashboardName, cluster.name, tpl.templateName]),
            mainTemplate=tpl,
            grafanaTemplates=grafanaTemplates + getCustomizableGrafanaTemplate(tpl, customizableGrafanaTemplateFunction),
            customParams={ rowName: rowName, instancePanels: instancePanels }  //params that are different for tableOverview and polystatOverview
          ).dashboard
        for cluster in $._config.clusterMonitoring.clusters
        for tpl in utils.getSpecificTemplates(utils.getTemplates(templateGroup, cluster), templateName)
        if utils.isCustomTemplate(cluster, tpl.templateName)
      } +
      if utils.isAnyDefaultTemplate($._config.clusterMonitoring.clusters, templateName) then
        {
          [jsonName]:
            local tpl = utils.getSpecificTemplate(utils.getTemplates(templateGroup), templateName);
            dashboardFunction(
              dashboardUid=dashboardUid,
              dashboardName=dashboardName,
              mainTemplate=tpl,
              grafanaTemplates=grafanaTemplates + getCustomizableGrafanaTemplate(tpl, customizableGrafanaTemplateFunction),
              customParams={ rowName: rowName, instancePanels: instancePanels }
            ).dashboard,
        }
      else
        {}
    else
      {},

  grafanaThresholds(thresholds)::
    /**
     * Create grafana threshold definition from configured thresholds.
     *
     * @param thresholds thresholds in format used in configuration.
     * @return grafana threshold steps object.
     */
    local severityColor(severity) =
      $._config.grafanaDashboards.color[$._config.grafanaDashboards.severityColors[severity]];

    if thresholds == {} then
      []
    else if std.objectHas(thresholds, 'operator') && thresholds.operator == '>=' then
      (
        if std.objectHas(thresholds, 'lowest') then [
          { color: severityColor('invalid'), value: null },
          { color: severityColor('default'), value: thresholds.lowest },
        ] else [
          { color: severityColor('default'), value: null },
        ]
      ) + (
        if std.objectHas(thresholds, 'warning') then [
          { color: severityColor('warning'), value: thresholds.warning },
        ] else []
      ) + (
        if std.objectHas(thresholds, 'critical') then [
          { color: severityColor('critical'), value: thresholds.critical },
        ] else []
      )
    else if std.objectHas(thresholds, 'operator') && thresholds.operator == '<' then
      local a0 =
        if std.objectHas(thresholds, 'lowest') && thresholds.lowest != null then {
          list: [{ color: severityColor('invalid'), value: null }],
          lastThreshold: thresholds.lowest,
        } else {
          list: [],
          lastThreshold: null,
        };
      local a1 =
        if std.objectHas(thresholds, 'critical') then {
          list: a0.list + [{ color: severityColor('critical'), value: a0.lastThreshold }],
          lastThreshold: thresholds.critical,
        } else a0;
      local a2 =
        if std.objectHas(thresholds, 'warning') then {
          list: a1.list + [{ color: severityColor('warning'), value: a1.lastThreshold }],
          lastThreshold: thresholds.warning,
        } else a1;
      a2.list + [{ color: severityColor('default'), value: a2.lastThreshold }]
    else  // allow custom thredhold definition
      [thresholds],
}
