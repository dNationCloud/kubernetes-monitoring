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
  zipWithIndex(arr)::
    /**
     * Enumarate array elements.
     *
     * @param arrays The input array.
     * @return indexed dict in form: { index:<array index>, item:<array element> }.
    */
    std.makeArray(std.length(arr), function(i) { index: i, item: arr[i] }),

  getTemplates(objTemplates, obj=null):: [
    tpl
    for tpl in [
      local objTemplate = objTemplates[tpl] { templateName: tpl };
      local parent =
        if std.objectHas(objTemplate, 'parent') then
          std.mergePatch($._config.templates.baseStatsTemplate, objTemplates[objTemplate.parent])
        else
          $._config.templates.baseStatsTemplate;
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
    tpl.alert
    for tpl in self.getTemplates(objTemplates, obj)
    if (std.objectHas(tpl, 'alert') && tpl.alert != {})
  ],

  getApps(objTemplates, obj)::
    if std.objectHas(obj, 'apps') && std.length(obj.apps) > 0 then
      [
        local templates = self.getTemplates(objTemplates, app);
        if std.length(std.prune(templates)) == 0 then
          app { templates: [std.mergePatch($._config.templates.baseStatsTemplate, objTemplates.genericApp) + { templateName: 'genericApp' }] }
        else
          app { templates: templates }
        for app in obj.apps
      ]
    else
      [],

  getAlertJobs(obj)::
    [
      obj.jobName,
    ] +
    [
      app.jobName
      for app in obj.apps
      if (std.objectHas(obj, 'apps') && std.length(obj.apps) > 0)
    ],

  isAnyDefault(obj):: std.length(std.prune([
    if std.objectHas(item, 'apps') || std.objectHas(item, 'templates') then
      null
    else
      true
    for item in obj
  ])) > 0,

  grafanaThresholds(thresholds)::
    /**
     * Create grafana threshold definition from configured thresholds
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
