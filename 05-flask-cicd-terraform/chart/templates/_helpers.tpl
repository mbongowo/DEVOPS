{{- define "urlshortener.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "urlshortener.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "urlshortener.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "urlshortener.labels" -}}
app.kubernetes.io/name: {{ include "urlshortener.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "urlshortener.selectorLabels" -}}
app.kubernetes.io/name: {{ include "urlshortener.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
