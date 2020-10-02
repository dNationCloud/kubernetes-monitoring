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
local config = (import 'config.libsonnet')._config;
local kube = import 'kube-libsonnet/kube.libsonnet';
local escapeDoubleBrackets = (import 'util.libsonnet').escapeDoubleBrackets;

local k8sObjectName(name) =
  /**
   * Construct k8s object name from name
   *
   * @param filename The input name string.
   * @return k8s object name.
   */
  '{{ $.Release.Name }}-%s' % name;

local k8sManifestFileName(name) =
  /**
   * Construct k8s manifest filename from name
   *
   * @param filename The input name string.
   * @return k8s manifest filename.
   */
  "%s.yaml" % name;

local dashboardJsonFileName(name) =
  /**
   * Construct dashboard json filename from name
   *
   * @param filename The input name string.
   * @return dashboard json filename.
   */
  "%s.json" % name;

local doNotChangeMessage = '# Do not change in-place. Generated from jsonnet template.\n\n';

{
  [k8sManifestFileName(filename)]:
    doNotChangeMessage +
    std.manifestYamlDoc(
      kube.ConfigMap(k8sObjectName(filename)) {
        metadata+: {
          namespace: '{{ $.Release.Namespace }}',
          labels: {
            grafana_dashboard: '1',
            app: '{{ $.Release.Name }}-grafana',
            release: '{{ $.Release.Name }}',
          },
        },
        data: {
          [dashboardJsonFileName(filename)]: escapeDoubleBrackets(std.toString(dashboards[filename])),
        },
      }
    )
  for filename in std.objectFields(dashboards)
} +

{
  [k8sManifestFileName(filename)]:
    doNotChangeMessage +
    std.manifestYamlDoc(
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'PrometheusRule',
        metadata: {
          name: k8sObjectName(filename),
          namespace: '{{ $.Release.Namespace }}',
          labels: {
            app: config.ruleCommon.appName,
            release: '{{ $.Release.Name }}',
          },
        },
        spec: rules[filename],
      }
    )
  for filename in std.objectFields(rules)
}
