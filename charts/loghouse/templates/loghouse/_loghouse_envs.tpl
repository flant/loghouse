{{- define "loghouse_envs" }}
env:
- name: KUBERNETES_DEPLOYED
  value: {{ now | quote }}
- name: DO_DB_DEPLOY
  value: {{ .Values.doDbDeploy | quote }}
- name: CLICKHOUSE_URL
  value: {{ template "clickhouseHttpService" $ }}
- name: CLICKHOUSE_SERVER
  value: {{ .Values.clickhouse.server | quote }}
- name: CLICKHOUSE_PORT
  value: {{ .Values.clickhouse.port | quote }}
- name: CLICKHOUSE_HTTP_PORT
  value: {{ .Values.clickhouse.httpPort | quote }}
- name: CLICKHOUSE_DATABASE
  value: {{ .Values.clickhouse.db | quote }}
- name: CLICKHOUSE_LOGS_TABLE
  value: {{ .Values.clickhouse.table | quote }}
- name: LOGS_TABLES_RETENTION_PERIOD
  value: {{ .Values.retention_period | quote }}
- name: LOGS_TABLES_HAS_BUFFER
  value: {{ .Values.clickhouse.hasBuffer | quote }}
- name: PERMISSONS_FILE_PATH
  value: "/config/user.conf"
- name: RACK_ENV
  value: "production"
envFrom:
- secretRef:
    name: clickhouse
{{- end }}
