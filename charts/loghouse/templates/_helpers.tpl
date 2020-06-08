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
{{- printf "%s:%.0f" .Values.clickhouse.server $httpPort | quote -}}
{{- else -}}
{{- printf "%s:%d" .Values.clickhouse.server $httpPort | quote -}}
{{- end -}}
{{- end -}}

{{/*
Fix clickhouse exporterPort
*/}}
{{- define "clickhouseExporterBind" -}}
{{- $exporterPort := .Values.clickhouse.exporterPort }}
{{- if eq (printf "%T" $exporterPort) "float64" -}}
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

{{/*
Convert pod limits to config bytes
*/}}
{{- define "toBytes" -}}
{{- $units := dict "" 1 "K" 1000 "Ki" 1024 "M" 1000000 "Mi" 1048576 "G" 1000000000 "Gi" 1073741824 "T" 1000000000000 "Ti" 1099511627776 "P" 1000000000000000 "Pi" 1125899906842624 "E" 1125899906842624 "Ei" 1152921504606846976 -}}
{{- if ne (printf "%T" .) "string" }}
{{- int64 . -}}
{{- else if regexMatch "[Ee][+-]?[0-9]" . }}
{{- int64 (float64 .) -}}
{{- else }}
{{- $memBase := regexFind "[0-9]+" . -}}
{{- $memMultiplier := pluck (regexFind "[EPTGMK]i?" .) $units | first | default 0 -}}
{{- mul $memBase $memMultiplier -}}
{{- end -}}
{{- end -}}

{{/*
Calculate max memory usage as input memory specification
without reserved memory. Result is 0 if input bytes is lower than reserved bytes.
*/}}
{{- define "toBytesWithoutReserved" -}}
{{- $input := include "toBytes" (first .) -}}
{{- $reserved := include "toBytes" (last .) -}}
{{- $memVal := (sub $input $reserved ) }}
{{- if ge $memVal 0 -}}
{{- $memVal -}}
{{- else -}}
0
{{- end -}}
{{- end -}}

{{/*
Fix string for percentage
*/}}
{{- define "clickhouseMaxDiskUsagePercentage" -}}
{{- $MaxDiskUsagePercentage := .Values.diskMaxUsagePersentage -}}
{{- if eq (printf "%T" $MaxDiskUsagePercentage) "float64" -}}
{{- $MaxDiskUsagePercentage := int64 $MaxDiskUsagePercentage -}}
{{- else if eq (printf "%T" $MaxDiskUsagePercentage) "string" }}
{{- $MaxDiskUsagePercentage := int64 (regexFind "[0-9]+" $MaxDiskUsagePercentage) -}}
{{- else -}}
{{- $MaxDiskUsagePercentage := int64 $MaxDiskUsagePercentage -}}
{{- end -}}
{{- if gt $MaxDiskUsagePercentage 99.0 -}}
80
{{- else -}}
{{- $MaxDiskUsagePercentage -}}
{{- end -}}
{{- end -}}