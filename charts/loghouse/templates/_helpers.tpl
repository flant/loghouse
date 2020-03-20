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

{{/*
Clickhouse max memory
*/}}
{{- define "clickhouseMaxMemory" -}}
{{- if .Values.clickhouse.resources.limits.memory -}}
{{- $memLimit := .Values.clickhouse.resources.limits.memory -}}
{{- $memUnit := (regexFind "[EPTGMK]i?|e" $memLimit) -}}
{{- $memMultiplier := (regexFind "[0-9]+" $memLimit) -}}
{{- if eq $memUnit "Ki" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1024) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- else if eq $memUnit "K" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1000) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- else if eq $memUnit "Mi" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1048576) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
{{- 0 -}}
{{- end -}}
{{- else if eq $memUnit "M" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1000000) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
{{- 0 -}}
{{- end -}}
{{- else if eq $memUnit "Gi" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1073741824) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- else if eq $memUnit "G" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1000000000) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- else if eq $memUnit "Ti" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1099511627776) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- else if eq $memUnit "T" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1000000000000) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- else if eq $memUnit "Pi" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1125899906842624) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- else if eq $memUnit "P" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1000000000000000) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- else if eq $memUnit "Ei" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1152921504606846976) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- else if eq $memUnit "E" -}}
{{- $clickhouseMemLimit := (sub (mul ($memMultiplier) 1000000000000000000) 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- else if eq $memUnit "e" -}}
{{- $clickhouseMemLimit := 0 -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- else -}}
{{- $clickhouseMemLimit := (sub $memLimit 268435456) -}}
{{- if not (regexFind "-" (toString $clickhouseMemLimit)) -}}
{{- $clickhouseMemLimit -}}
{{- else -}}
0
{{- end -}}
{{- end -}}
{{- else -}}
0
{{- end -}}
{{- end -}}