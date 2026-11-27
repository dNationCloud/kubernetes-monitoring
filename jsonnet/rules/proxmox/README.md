# Proxmox VE alerting rules

Prometheus alert rules for Proxmox VE clusters (nodes and Ceph), kept apart from
the Kubernetes alerting (`rules.jsonnet`, `templates.libsonnet`). They are
rendered by the jsonnet translator into their own PrometheusRule
`prometheus-rules-proxmox-generated` and evaluated by Thanos Ruler.

How to enable them, the alert list, thresholds and test results are in
`alerting.md` of the Proxmox setup bundle. This file is for changing the rules.

## Files


| File                                                                           | What it does                                                                                                                                                      |
| ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `config.libsonnet`                                                             | Default settings of every alert: threshold type, operator, warning and critical level,`for` duration, extra labels; metric selectors; alert name prefix and group |
| `nodes.libsonnet`                                                              | Node alert definitions: PromQL expression per threshold type and alert message                                                                                    |
| `ceph.libsonnet`                                                               | Ceph alert definitions, same structure                                                                                                                            |
| `lib.libsonnet`                                                                | Generator: turns a definition and its settings into one rule per level, adds the cluster selector, builds per-cluster overrides                                   |
| `../../rules-proxmox.jsonnet`                                                  | Entry point: merges the Helm values (`proxmoxRules`) over `config.libsonnet` and writes `proxmox-nodes` and `proxmox-ceph` rule groups                            |
| `../../../chart/templates/rules/proxmox-rules.yaml`                            | ConfigMap with the packed jsonnet and the Helm values, read by the translator                                                                                     |
| `../../../chart/values.yaml` (`proxmoxRules`)                                  | Switch, target object, labels and threshold overrides                                                                                                             |

In short: **thresholds go to Helm values, new or changed alerts go to
`nodes.libsonnet` / `ceph.libsonnet` with their defaults in `config.libsonnet`.**

## Why it is separate

- **Own PrometheusRule.** The ConfigMap carries the translator annotation
  `prometheus_rules_object_name`, so the translator (2.1.0 or newer) writes the
  Proxmox rules to their own object with their own label instead of merging them
  into the Kubernetes rules. Otherwise one label would either put the Proxmox
  rules into Prometheus, where they never fire, or move the Kubernetes rules out
  of Prometheus and silently stop every Kubernetes alert.
- **Only Proxmox series.** Proxmox node_exporter uses the same job name as
  Kubernetes nodes; the `platform="proxmox"` selector keeps the rules from
  reading the node metrics of every cluster (2391 series instead of 12).

## Adding or changing an alert

1. Add the definition to `nodes.libsonnet` or `ceph.libsonnet`: `name`,
   `source` (`pve`, `node`, `smart` or `ceph`, selects the metric selector),
   `message`, and `expr` with one PromQL expression per supported threshold
   type. Put `%(selector)s` into every metric selector of the expression. The
   expression returns the value only; the generator appends the comparison. When
   the value has a different unit per type, give `message` one text per type.
2. Add its defaults to `alerts` in `config.libsonnet` under the same key.
3. Check the output: `make json-rules-proxmox` writes the rules to
   `json/proxmox-nodes.json` and `json/proxmox-ceph.json`.
4. `make jsonnet-package-rules` packs the jsonnet into the chart.
