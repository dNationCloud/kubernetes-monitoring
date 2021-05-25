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

/* VM prometheus rules */

{
  prometheusRules+::
    if $.isClusterMonitoring() then {
      'vms.rules': {
        local alerts = std.set(
          std.flattenArrays([
            $.getTemplateAlerts($._config.templates.L2.vm, vm)
            for cluster in $._config.clusterMonitoring.clusters
            if (std.objectHas(cluster, 'vms') && std.length(cluster.vms) > 0)
            for vm in cluster.vms
          ]), function(o) o.name
        ),
        groups: [
          $.newRuleGroup('vm.rules')
          .addRules(
            std.flattenArrays(
              [
                $.newAlertPair(
                  name=alert.name,
                  message=alert.message,
                  expr=alert.expr % std.makeArray(std.length(std.findSubstr('job=~"%s"', alert.expr)), function(x) std.join('|', $.vmJobs)),
                  thresholds=alert.thresholds,
                  link=alert.link,
                  customLables=alert.customLables,
                )
                for alert in alerts
              ]
            ) +
            [
              $.newAlert(
                name='VMTargetAbsent',
                message='VM job {{ $labels.job }}: Target is absent.',
                expr='absent(up{job="%s"})' % vmJob,
                operator='==',
                threshold=1,
                link='',
                labels={ severity: 'critical', alertgroup: $._config.prometheusRules.alertGroupClusterVM },
              )
              for vmJob in $.vmJobs
            ]
          ),
        ],
      },
    }
    else {},
}
