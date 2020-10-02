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

(import '../config.libsonnet') +
(import '../util.libsonnet') +

{
  newRuleGroup(name):: {
    name: name,
    rules: [],
    alertFullName(name):: '%s%s' % [$._config.ruleCommon.alertNamePrefix, name],

    addAlert(name, message, expr, threshold, severity):: self {
      local ruleGroup = self,
      rules+: [{
        alert: ruleGroup.alertFullName(name),
        annotations: {
          message: $.escapeDoubleBrackets(message),
        },
        expr: '%s < %s' % [expr, threshold],
        'for': '5m',
        labels: {
          severity: severity,
        },
      }],
    },

    thresholdExpression(alertName, severity, default)::
      '{{ if .Values.alertThresholds }}' +
      '{{ if .Values.alertThresholds.%s }}' % self.alertFullName(alertName) +
      '{{ .Values.alertThresholds.%s.%s | default %s }}' % [self.alertFullName(alertName), severity, default] +
      '{{ else }}%s{{ end }}' % default +
      '{{ else }}%s{{ end }}' % default,

    addAlertPair(name, message, expr):: self
      .addAlert(name, message, expr, self.thresholdExpression(name, 'critical', $._config.ruleCommon.thresholds.critical), 'critical')
      .addAlert(name, message, expr, self.thresholdExpression(name, 'warning', $._config.ruleCommon.thresholds.warning), 'warning')

  },
} +

// dNation rules
(import 'k8s/rules.libsonnet')
