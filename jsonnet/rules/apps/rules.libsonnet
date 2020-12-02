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

/* Application prometheus rules */

{
  hostApps:: std.flattenArrays([host.apps for host in $._config.hostMonitoring.hosts if std.objectHas(host, 'apps')]),
  prometheusRules+::
    if std.length($._config.appMonitoring.apps) > 0 && $._config.appMonitoring.enabled then
      {
        'apps.rules': {
          local ruleTemplates(app, templates, alertgroup) =
            [
              if template.name == 'pythonFlask' then
                $.newAlertPair(
                  name='%sPythonFlaskSuccessRateLow' % alertgroup,
                  message='%s {{ $labels.job }}: Python Flask Success Rate (non-4|5xx responses) Low {{ $value }}%s' % [alertgroup, '%'],
                  expr=$._config.templates.pythonFlask.expr % { job: 'job=~".+"' },
                  thresholds=$._config.templates.pythonFlask.thresholds,
                  customLables={ alertgroup: alertgroup },
                )
              else if template.name == 'javaActuator' then
                $.newAlertPair(
                  name='%sJavaActuatorHeapHigh' % alertgroup,
                  message='%s {{ $labels.job }}: Java Actuator Heap High {{ $value }}%s' % [alertgroup, '%'],
                  expr=$._config.templates.javaActuator.expr % { job: 'job=~".+"' },
                  thresholds=$._config.templates.javaActuator.thresholds,
                  customLables={ alertgroup: alertgroup },
                )
              else if template.name == 'cAdvisor' then
                $.newAlertPair(
                  name='%sCAdvisorHealthLow' % alertgroup,
                  message='%s {{ $labels.job }}: cAdvisor Health Low {{ $value }}%s' % [alertgroup, '%'],
                  expr=$._config.templates.defaultApp.expr % { job: 'job=~".+"' },
                  thresholds=$._config.templates.defaultApp.thresholds,
                  customLables={ alertgroup: alertgroup },
                )
              else
                []
              for template in templates
            ],
          groups: [
            $.newRuleGroup('apps.rules')
            .addRules(
              // Add application rules
              std.set(
                std.flattenArrays(
                  std.flattenArrays(
                    [
                      ruleTemplates(app, app.templates, $._config.prometheusRules.alertGroupApp)
                      for app in $._config.appMonitoring.apps
                    ]
                  )
                )
                , function(o) (o.name + o.labels)
              ) +
              // Add host application rules
              std.set(
                std.flattenArrays(
                  std.flattenArrays(
                    [
                      ruleTemplates(app, app.templates, $._config.prometheusRules.alertGroupHostApp)
                      for app in $.hostApps
                    ]
                  )
                )
                , function(o) (o.name + o.labels)
              )
            ),
          ],
        },
      }
    else {},
}
