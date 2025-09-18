{{- define "gemx.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gemx.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gemx.labels" -}}
app.kubernetes.io/name: {{ include "gemx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end -}}

{{- define "gemx.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gemx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
