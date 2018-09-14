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