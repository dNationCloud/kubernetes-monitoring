{{/* Helpers variables */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "k8s-monitoring.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "k8s-monitoring.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "k8s-monitoring.namespace" -}}
{{- if .Values.namespaceOverride -}}
{{- .Values.namespaceOverride -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Generate basic labels
*/}}
{{- define "k8s-monitoring.labels" -}}
{{- if .Values.commonLabels -}}
{{- toYaml .Values.commonLabels -}}
{{- end -}}
{{- end -}}

{{/*
Release name override
For development purposes only.
Prometheus operator discovers and filters service and pod monitors based on release label
*/}}
{{- define "k8s-monitoring.release" -}}
{{- if .Values.releaseOverride -}}
{{- .Values.releaseOverride -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
Helper prints
*/}}
{{- define "grafanaLabelAssignment" -}}
{{- $labelKey := first (keys .Values.grafanaDashboards.labelGrafana) -}}
{{- $labelValue := first (values .Values.grafanaDashboards.labelGrafana) -}}
{{ printf "%s=%s" $labelKey $labelValue }}
{{- end -}}

{{- define "prometheusLabelAssignment" -}}
{{- $labelKey := first (keys .Values.prometheusRules.labelPrometheus) -}}
{{- $labelValue := first (values .Values.prometheusRules.labelPrometheus) -}}
{{ printf "%s=%s" $labelKey $labelValue }}
{{- end -}}
