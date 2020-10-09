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
}
