{{/*
Ingress api version
*/}}
{{- define "Ingress.apiVersion" -}}
{{- if semverCompare ">=1.14" .Capabilities.KubeVersion.GitVersion -}}
"networking.k8s.io/v1beta1"
{{- else -}}
"extensions/v1beta1"
{{- end -}}
{{- end -}}

{{/*
Fluentd insert table
*/}}
{{- define "fluentdInsertTable" -}}
{{- if and .Values.clickhouse.hasBuffer -}}
{{- printf "%s_buffer" .Values.clickhouse.table -}}
{{- else -}}
{{- .Values.clickhouse.table -}}
{{- end -}}
{{- end -}}

{{/*
Fix clickhouse httpport
*/}}
{{- define "clickhouseHttpService" -}}
{{- $httpPort := .Values.clickhouse.httpPort }}
{{- $type := printf "%T" $httpPort }}
{{- if eq $type "float64" -}}
{{ printf "%s:%.0f" .Values.clickhouse.server $httpPort | quote }}
{{- else -}}
{{- printf "%s:%d" .Values.clickhouse.server $httpPort | quote -}}
{{- end -}}
{{- end -}}

{{/*
Fix clickhouse exporterPort
*/}}
{{- define "clickhouseExporterBind" -}}
{{- $exporterPort := .Values.clickhouse.exporterPort }}
{{- $type := printf "%T" $exporterPort }}
{{- if eq $type "float64" -}}
{{ printf ":%.0f" $exporterPort | quote }}
{{- else -}}
{{- printf ":%d" $exporterPort | quote }}
{{- end -}}
{{- end -}}

{{/*
Images version. This version can be set from cli: --set version=latest or --set version=0.2.1
Chart.Version is set to latest in master branch. helm package rewrite it to tag value for releases.
*/}}
{{- define "app.version" -}}
{{- if .Values.version -}}
{{- .Values.version -}}
{{- else -}}
{{- .Chart.Version -}}
{{- end -}}
{{- end -}}

{{- define "includeByName" -}}
{{- $val := (pluck .name .root | first) -}}
{{- if $val -}}
{{- dict .name $val | toYaml -}}
{{- end -}}
{{- end -}}

{{/*
PVC name
*/}}
{{- define "clickhousePvcName" -}}
{{- if .Values.storage.pvc.name -}}
{{- .Values.storage.pvc.name | quote -}}
{{- else }}
"clickhouse"
{{- end -}}
{{- end -}}
