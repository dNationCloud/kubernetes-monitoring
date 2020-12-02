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
  grafanaThresholds(thresholds, lowestValue=null)::
    /**
     * Create grafana threshold definition from configured thresholds
     *
     * @param thresholds thresholds in format used in configuration.
     * @param lowestValue value for lowest grafana threshold (default null for minus infinity).
     * @return grafana threshold steps object.
     */
    if thresholds.operator == '>=' then
      [{ color: $._config.grafanaDashboards.color.green, value: lowestValue }] + (
        if std.objectHas(thresholds, 'warning') then [
          { color: $._config.grafanaDashboards.color.orange, value: thresholds.warning },
        ] else []
      ) + (
        if std.objectHas(thresholds, 'critical') then [
          { color: $._config.grafanaDashboards.color.red, value: thresholds.critical },
        ] else []
      )
    else
      assert thresholds.operator == '<';
      local a0 = {
        list: [],
        lastThreshold: lowestValue,
      };
      local a1 =
        if std.objectHas(thresholds, 'critical') then {
          list: a0.list + [{ color: $._config.grafanaDashboards.color.red, value: a0.lastThreshold }],
          lastThreshold: thresholds.critical,
        } else a0;
      local a2 =
        if std.objectHas(thresholds, 'warning') then {
          list: a1.list + [{ color: $._config.grafanaDashboards.color.orange, value: a1.lastThreshold }],
          lastThreshold: thresholds.warning,
        } else a1;
      a2.list + [{ color: $._config.grafanaDashboards.color.green, value: a2.lastThreshold }],

}
