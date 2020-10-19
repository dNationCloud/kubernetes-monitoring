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

/* Module comprises the logic to encapsulate grafana dashboards writted in jsonnet into k8s configmaps */

local dashboards = (import 'dashboards/dashboards.libsonnet').grafanaDashboards;
local rules = (import 'rules/rules.libsonnet').prometheusRules;
local kube = import 'kube-libsonnet/kube.libsonnet';
local util = import 'util.libsonnet';

local doNotChangeMessage = '# Do not change in-place. Generated from jsonnet template.\n\n';

{
  [util.k8sManifestFileName(filename)]:
    doNotChangeMessage +
    std.manifestYamlDoc(
      kube.ConfigMap(util.k8sObjectName(filename)) {
        metadata+: {
          namespace: '{{ include "k8s-m8g.namespace" . }}',
          labels: {
            app: '{{ include "k8s-m8g.name" . }}',
            release: '{{ $.Release.Name }}',
            '{{ .Values.dashboardLabel.name }}': '{{ .Values.dashboardLabel.value }}',
          },
        },
        data: {
          [util.dashboardJsonFileName(filename)]: util.escapeDoubleBrackets(std.toString(dashboards[filename])),
        },
      }
    )
  for filename in std.objectFields(dashboards)
} +

{
  [util.k8sManifestFileName(filename)]:
    doNotChangeMessage +
    std.manifestYamlDoc(
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'PrometheusRule',
        metadata: {
          name: util.k8sObjectName(filename),
          namespace: '{{ include "k8s-m8g.namespace" . }}',
          labels: {
            app: '{{ include "k8s-m8g.name" . }}',
            release: '{{ $.Release.Name }}',
            '{{ .Values.ruleLabel.name }}': '{{ .Values.ruleLabel.value }}',
          },
        },
        spec: rules[filename],
      }
    )
  for filename in std.objectFields(rules)
}
