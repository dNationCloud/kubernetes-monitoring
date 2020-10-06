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
local config = (import 'dashboards/dashboards.libsonnet')._config;
local kube = import 'kube-libsonnet/kube.libsonnet';

local dashboardToString(dashboard) =
  /**
   * Parse grafana dashboard and replace {{.*}} by {{`{{`}}.*{{`}}`}}
   * Helm chart as a consumer of generated grafana dashboard uses the same format of variable definition as grafana.
   * The grafana dashboard variables need to be escaped to resolve this conflict.
   *
   * @param dashboard The input dashboard object.
   * @return parsed dashboard as a string.
   */
  std.strReplace(
    std.strReplace(
      std.strReplace(
        std.strReplace(
          std.toString(dashboard), '{{', '{{`{{'
        ), '}}', '}}`}}'
      ), '{{`{{', '{{`{{`}}'
    ), '}}`}}', '{{`}}`}}'
  );

local dashboardConfigMapName(filename) =
  /**
   * Parse k8s configmap name from the dashboard filename
   *
   * @param filename The input filename string.
   * @return k8s configmap name.
   */
  '{{ $.Release.Name }}-%(name)s' % std.strReplace(filename, '.json', '');

local dashboardConfigMapFileName(filename) =
  /**
   * Parse k8s configmap filename from the dashboard filename
   *
   * @param filename The input filename string.
   * @return k8s configmap filename.
   */
  std.strReplace(filename, '.json', '.yaml');

local doNotChangeMessage = '# Do not change in-place. Generated from jsonnet template.\n\n';

{
  [dashboardConfigMapFileName(filename)]:
    doNotChangeMessage +
    std.manifestYamlDoc(
      kube.ConfigMap(dashboardConfigMapName(filename)) {
        metadata+: {
          labels: {
            grafana_dashboard: '1',
            app: '{{ $.Release.Name }}-grafana',
          },
          namespace: '{{ $.Release.Namespace }}',
          annotations+:
            if config.dashboardDirs.enable then { 'k8s-sidecar-target-directory': config.dashboardDirs[filename] } else {},
        },
        data: {
          [filename]: dashboardToString(dashboards[filename]),
        },
      }
    )
  for filename in std.objectFields(dashboards)
}
