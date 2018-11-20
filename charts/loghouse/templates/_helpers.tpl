{{/*
CronJob api version
*/}}
{{- define "CronJob.apiVersion" -}}
{{- if semverCompare ">=1.8" .Capabilities.KubeVersion.GitVersion -}}
"batch/v1beta1"
{{- else -}}
"batch/v2alpha1"
{{- end -}}
{{- end -}}


{{/*
Images version. This version can be set from cli: --set app.version=master.
*/}}
{{- define "app.version" -}}
{{- if .Values.app.version -}}
{{- .Values.app.version -}}
{{- else -}}
{{- .Chart.AppVersion -}}
{{- end -}}
{{- end -}}
