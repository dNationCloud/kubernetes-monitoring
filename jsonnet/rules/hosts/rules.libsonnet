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

/* K8s prometheus rules */

{
  prometheusRules+::
    if $.isHostMonitoring() then {
      'hosts.rules': {
        local alerts = std.set(
          std.flattenArrays([
            $.getTemplateAlerts($._config.templates.L1.host, host)
            for host in $._config.hostMonitoring.hosts
          ]), function(o) o.name
        ),
        groups: [
          $.newRuleGroup('host.rules')
          .addRules(
            std.flattenArrays(
              [
                $.newAlertPair(
                  name=alert.name,
                  message=alert.message,
                  expr=alert.expr,
                  thresholds=alert.thresholds,
                  link=alert.link,
                  customLables=alert.customLables,
                )
                for alert in alerts
              ]
            )
          ),
        ],
      },
    }
    else {},
}
