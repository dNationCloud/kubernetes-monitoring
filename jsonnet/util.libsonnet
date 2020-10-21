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

local config = (import 'config.libsonnet')._config;

{
  escapeDoubleBrackets(string)::
    /**
     * Replace {{.*}} by {{`{{`}}.*{{`}}`}}
     * Helm chart as a consumer of generated grafana dashboards and prometheus rules uses the same format of variables
     * as grafana and prometheus.
     * The grafana and prometheus variables need to be escaped to resolve this conflict.
     *
     * @param string The input string.
     * @return string String with escaped double brackets.
     */
    std.strReplace(
      std.strReplace(
        std.strReplace(
          std.strReplace(
            string, '{{', '{{`{{'
          ), '}}', '}}`}}'
        ), '{{`{{', '{{`{{`}}'
      ), '}}`}}', '{{`}}`}}'
    ),

  k8sObjectName(name)::
    /**
     * Construct k8s object name from name
     *
     * @param filename The input name string.
     * @return k8s object name.
     */
    '{{ include "k8s-monitoring.fullname" . }}-%s' % name,

  k8sManifestFileName(name)::
    /**
     * Construct k8s manifest filename from name
     *
     * @param filename The input name string.
     * @return k8s manifest filename.
     */
    '%s.yaml' % name,

  dashboardJsonFileName(name)::
    /**
     * Construct dashboard json filename from name
     *
     * @param filename The input name string.
     * @return dashboard json filename.
     */
    '%s.json' % name,

  grafanaThresholds(thresholds, lowestValue=null)::
    /**
     * Create grafana threshold definition from configured thresholds
     *
     * @param thresholds thresholds in format used in configuration.
     * @param lowestValue value for lowest grafana threshold (default null for minus infinity).
     * @return grafana threshold steps object.
     */
    std.filter(function(v) v != null,
      if thresholds.operator == '>=' then
        [
          { color: config.dashboardCommon.color.green, value: lowestValue },
          if std.objectHas(thresholds, 'warning') then { color: config.dashboardCommon.color.orange, value: thresholds.warning },
          if std.objectHas(thresholds, 'critical') then { color: config.dashboardCommon.color.red, value: thresholds.critical },
        ]
      else
        assert thresholds.operator == '<';
        local lowerThreshold = if std.objectHas(thresholds, 'critical') then thresholds.critical else thresholds.warning;
        local higherThreshold = if std.objectHas(thresholds, 'warning') then thresholds.warning else thresholds.critical;
        [
          if std.objectHas(thresholds, 'critical') && (lowerThreshold == thresholds.critical) then
            { color: config.dashboardCommon.color.red, value: lowestValue }
          else
            { color: config.dashboardCommon.color.orange, value: lowestValue },
          if higherThreshold != lowerThreshold then
            if higherThreshold == thresholds.critical then
              { color: config.dashboardCommon.color.red, value: lowerThreshold }
            else
              { color: config.dashboardCommon.color.orange, value: lowerThreshold },
          { color: config.dashboardCommon.color.green, value: higherThreshold },
        ],
    ),
}
