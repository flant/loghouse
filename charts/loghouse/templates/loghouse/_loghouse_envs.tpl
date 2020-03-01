{{- define "loghouse_envs" }}
env:
- name: KUBERNETES_DEPLOYED
  value: {{ now | quote }}
- name: DO_DB_DEPLOY
  value: {{ .Values.doDbDeploy | quote }}
- name: CLICKHOUSE_URL
  value: "clickhouse:8123"
- name: CLICKHOUSE_DATABASE
  value: {{ .Values.clickhouse.db | quote }}
- name: CLICKHOUSE_LOGS_TABLE
  value: {{ .Values.clickhouse.table | quote }}
- name: LOGS_TABLES_RETENTION_PERIOD
  value: {{ .Values.retention_period | quote }}
- name: LOGS_TABLES_HAS_BUFFER
  value: {{ .Values.clickhouse.has_buffer | quote }}
- name: PERMISSONS_FILE_PATH
  value: "/config/user.conf"
- name: RACK_ENV
  value: "production"
- name: CLICKHOUSE_USERNAME
  valueFrom:
    secretKeyRef:
      name: clickhouse
      key: CLICKHOUSE_USER
envFrom:
- secretRef:
    name: clickhouse
{{- end }}
