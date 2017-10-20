#!/bin/bash

set -e

! read -rd '' HELP_STRING <<"EOF"
Usage: ctl.sh [OPTION]... [-i|--install] KUBE_HOST
   or: ctl.sh [OPTION]...

Install FCHT (Fluentd, ClickHouse, Tabix) stack to Kubernetes cluster.

Mandatory arguments:
  -i, --install                install into 'kube-logging' namespace
  -u, --upgrade                upgrade existing installation, will reuse password and host names
  -d, --delete                 remove everything, including the namespace

Optional arguments:
  --storage-class-name         name of the storage class
  --storage-size               storage size with optional IEC suffix
  --storage-namespace          set name of namespace from what copy secret
  --hostpath                   if use hostpath, enter path
  --https                      disable Lets Encrypt for domains
  --branch                     use specific branch

Optional arguments:
  -h, --help                   output this message
EOF

RANDOM_NUMBER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1)
TMP_DIR="/tmp/loghouse-$RANDOM_NUMBER"
WORKDIR="$TMP_DIR/loghouse"
DEPLOY_SCRIPT="./deploy.sh"
TEARDOWN_SCRIPT="./teardown.sh"
UPGRADE_SCRIPT="./upgrade.sh"

MODE=""
USER=admin
NAMESPACE="kube-logging"
FIRST_INSTALL="true"
STORAGE_CLASS_NAME="rbd"
STORAGE_SIZE="20Gi"
CLICKHOUSE_DB="logs"
K8S_LOGS_TABLE="logs"
BRANCH="master"
HELM_ARGS=""

TEMP=$(getopt -o i,u,d,h --long help,install,upgrade,delete,storage-class-name:,storage-size:,storage-namespace:,https:,branch:,hostpath: \
             -n 'ctl' -- "$@")

eval set -- "$TEMP"

while true; do
  case "$1" in
    -i | --install )
      MODE=install; shift ;;
    -u | --upgrade )
      MODE=upgrade; shift ;;
    -d | --delete )
      MODE=delete; shift ;;
    --storage-class-name )
      STORAGE_CLASS_NAME="$2"; shift 2;;
    --storage-size )
      STORAGE_SIZE="$2"; shift 2;;
    --storage-namespace )
      STORAGE_NAMESPACE="$2"; shift 2;;
    --https )
      HTTPS="$2"; shift 2;;
    --branch )
      BRANCH="$2"; shift 2;;
    --hostpath )
      HOSTPATH="$2"; shift 2;;
    -h | --help )
      echo "$HELP_STRING"; exit 0 ;;
    -- )
      shift; break ;;
    * )
      break ;;
  esac
done

if [ ! "$MODE" ]; then echo "Mode of operation not provided. Use '-h' to print proper usage."; exit 1; fi

type curl >/dev/null 2>&1 || { echo >&2 "I require curl but it's not installed.  Aborting."; exit 1; }
type base64 >/dev/null 2>&1 || { echo >&2 "I require base64 but it's not installed.  Aborting."; exit 1; }
type git >/dev/null 2>&1 || { echo >&2 "I require git but it's not installed.  Aborting."; exit 1; }
type kubectl >/dev/null 2>&1 || { echo >&2 "I require kubectl but it's not installed.  Aborting."; exit 1; }
type jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed.  Aborting."; exit 1; }
type htpasswd >/dev/null 2>&1 || { echo >&2 "I require htpasswd but it's not installed. Please, install 'apache2-utils'. Aborting."; exit 1; }
type sha256sum >/dev/null 2>&1 || { echo >&2 "I require sha256sum but it's not installed. Aborting."; exit 1; }


SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"
git clone --depth 1 -b ${BRANCH} https://github.com/qw1mb0/loghouse.git
#cp -r ${SRC_DIR} ${TMP_DIR} 
cd "$WORKDIR"

function install {
  PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
  PASSWORD_BASE64=$(echo -n "$PASSWORD" | base64 -w0)
  BASIC_AUTH_SECRET=$(echo "$PASSWORD" | htpasswd -ni admin | base64 -w0)
  CLICKHOUSE_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
  CLICKHOUSE_PASS_SHA256=$(echo -n $CLICKHOUSE_PASS | sha256sum | tr -d '-' | tr -d ' ')
  CLICKHOUSE_HOST="clickhouse$KUBE_HOST"
  TABIX_HOST="tabix$KUBE_HOST"
  LOGHOUSE_HOST="loghouse$KUBE_HOST"
  # install basic-auth secret
  HELM_ARGS="${HELM_ARGS} --set auth=${BASIC_AUTH_SECRET}"
  #sed -i -e "s%##BASIC_AUTH_SECRET##%$BASIC_AUTH_SECRET%" -e "s%##PLAINTEXT_PASSWORD##%$PASSWORD_BASE64%" manifests/ingress/basic-auth-secret.yaml
  # install ingress host
  if [ "$HTTPS" == "false" ] ;
  then
    echo "Without HTTPS"
  else
    HELM_ARGS="${HELM_ARGS} --set https=true"
  fi
  HELM_ARGS="${HELM_ARGS} --set clickhouse_host=${CLICKHOUSE_HOST}"
  HELM_ARGS="${HELM_ARGS} --set loghouse_host=${LOGHOUSE_HOST}"
  HELM_ARGS="${HELM_ARGS} --set tabix_host=${TABIX_HOST}"
  if [ -n "$HOSTPATH" ] ; 
  then
    HELM_ARGS="${HELM_ARGS} --set hostpath=${HOSTPATH}"
  else
    # set storage for clickhouse
    HELM_ARGS="${HELM_ARGS} --set pvc.size=${STORAGE_SIZE}"
    HELM_ARGS="${HELM_ARGS} --set pvc.storagClassName=${STORAGE_CLASS_NAME}"
  fi
  # set clickhouse password
  HELM_ARGS="${HELM_ARGS} --set clickhouse_pass_sha256=${CLICKHOUSE_PASS_SHA256}"
  HELM_ARGS="${HELM_ARGS} --set clickhouse_pass_original=${CLICKHOUSE_PASS}"

  if [ -n "$STORAGE_NAMESPACE" ] ;
  then
    export STORAGE_NAMESPACE=$STORAGE_NAMESPACE
    export STORAGE_CLASS_NAME=$STORAGE_CLASS_NAME
    STORAGECLASS_USER_SECRET_NAME=$(kubectl -n $STORAGE_NAMESPACE get storageclass $STORAGE_CLASS_NAME -o json | jq '.parameters.userSecretName' | tr -d '"')
    STORAGECLASS_USER_SECRET_VALUE=$(kubectl -n $STORAGE_NAMESPACE get secret $STORAGECLASS_USER_SECRET_NAME -o json | jq '.data.key' | tr -d '"')
    HELM_ARGS="${HELM_ARGS} --set rbd_sc_name=${STORAGECLASS_USER_SECRET_NAME}"
    HELM_ARGS="${HELM_ARGS} --set rbd_key=${STORAGECLASS_USER_SECRET_VALUE}"
  fi
  echo "HELM_ARGS: ${HELM_ARGS}"
  #helm install --dry-run --namespace "${NAMESPACE}" ${HELM_ARGS} .helm/ --dry-run
  pwd
  echo helm install --namespace "${NAMESPACE}" ${HELM_ARGS} ${WORKDIR}/.helm/ --wait
  helm install --namespace "${NAMESPACE}" ${HELM_ARGS} ${WORKDIR}/.helm/ --wait
  sleep 25
  echo kubectl --namespace "${NAMESPACE}" exec $(kubectl --namespace "$NAMESPACE" get pod | grep clickhouse-server | awk '{print $1}') /usr/local/bin/init.sh
  kubectl --namespace "${NAMESPACE}" exec $(kubectl --namespace "$NAMESPACE" get pod | grep clickhouse-server | awk '{print $1}') /usr/local/bin/init.sh
  echo '##################################'
  echo 'Basic auth for loghouse and tabix'
  echo "Login: admin"
  echo "Password: $PASSWORD"
  echo '##################################'
  echo 'Auth for clickhouse user'
  echo 'Login: default'
  echo "Password: $CLICKHOUSE_PASS"
  echo '#################################'
}

function upgrade {
  PASSWORD=$(kubectl -n "$NAMESPACE" get secret basic-auth -o json | jq .data.password -r | base64 -d)
  PASSWORD_BASE64=$(echo -n "$PASSWORD" | base64 -w0)
  BASIC_AUTH_SECRET=$(echo "$PASSWORD" | htpasswd -ni admin | base64 -w0)
  KUBE_HOST="$(kubectl -n "$NAMESPACE" get ingress clickhouse -o yaml | grep "host:" | cut -d . -f 2-)"
  # Get clickhouse variables
  CLICKHOUSE_HOST="clickhouse.$KUBE_HOST"
  STORAGECLASS_USER_SECRET_VALUE=$(kubectl -n kube-logging get secret -l storage=clickhouse -o yaml | grep "key:" | awk '{print $2}')
  STORAGECLASS_USER_SECRET_NAME=$(kubectl -n kube-logging get secret -l storage=clickhouse -o yaml | grep "name:" | awk '{print $2}')
  STORAGE_SIZE=$(kubectl -n kube-logging get persistentvolumeclaim  clickhouse -o yaml | grep storage: | tail -n 1 | awk '{print $2}')
  STORAGE_CLASS_NAME=$(kubectl -n kube-logging get persistentvolumeclaim  clickhouse -o yaml | grep storageClassName: |  awk '{print $2}')
  CLICKHOUSE_PASS=$(kubectl -n "$NAMESPACE" get deploy clickhouse-server -o yaml | grep 'name: CLICKHOUSE_PASS' -A1 | grep 'value: ' | awk '{print $NF}')
  CLICKHOUSE_DB=$(kubectl -n "$NAMESPACE" get deploy clickhouse-server -o yaml | grep 'name: CLICKHOUSE_DB' -A1 | grep 'value: ' | awk '{print $NF}')
  K8S_LOGS_TABLE=$(kubectl -n "$NAMESPACE" get deploy clickhouse-server -o yaml | grep 'name: K8S_LOGS_TABLE' -A1 | grep 'value: ' | awk '{print $NF}')
  CLICKHOUSE_PASS_SHA256=$(kubectl -n "$NAMESPACE" get cm clickhouse-config -o yaml | grep '<password_sha256_hex>' | cut -f2 -d'>' | cut -f1 -d'<')
  #Get tabix
  TABIX_HOST="tabix.$KUBE_HOST"
  # Get loghouse variables
  LOGHOUSE_HOST="loghouse.$KUBE_HOST"
  # check https
  if ! kubectl -n "$NAMESPACE" get ing loghouse -o yaml | grep 'tls-acme' > /dev/null; then
    HTTPS="false"
  fi
  # install basic-auth secret
  sed -i -e "s%##BASIC_AUTH_SECRET##%$BASIC_AUTH_SECRET%" -e "s%##PLAINTEXT_PASSWORD##%$PASSWORD_BASE64%" manifests/ingress/basic-auth-secret.yaml
  # install ingress host
  if [ "$HTTPS" == "false" ] ;
  then
    sed -i -e 's/  annotations:/  annotations:\n    ingress.kubernetes.io\/force-ssl-redirect: "false"\n    ingress.kubernetes.io\/ssl-redirect: "false"/' manifests/ingress/clickhouse.yaml
    sed -i -e 's/  annotations:/  annotations:\n    ingress.kubernetes.io\/force-ssl-redirect: "false"\n    ingress.kubernetes.io\/ssl-redirect: "false"/' manifests/ingress/loghouse.yaml
    sed -i -e 's/  annotations:/  annotations:\n    ingress.kubernetes.io\/force-ssl-redirect: "false"\n    ingress.kubernetes.io\/ssl-redirect: "false"/' manifests/ingress/tabix.yaml
    # prepare url to clickhouse for loghouse
    sed -i -e "s/##CLICKHOUSE_HOST##/http:\/\/$CLICKHOUSE_HOST/g" manifests/loghouse/loghouse.yaml
  else
    # enable LE (tls-acme)
    sed -i -e 's/  annotations:/  annotations:\n    kubernetes.io\/tls-acme: "true"/' manifests/ingress/clickhouse.yaml
    sed -i -e 's/  annotations:/  annotations:\n    kubernetes.io\/tls-acme: "true"/' manifests/ingress/loghouse.yaml
    sed -i -e 's/  annotations:/  annotations:\n    kubernetes.io\/tls-acme: "true"/' manifests/ingress/tabix.yaml
    # add tls section
    sed -i -e "\$a\ \ tls:\n  - hosts:\n    - ##CLICKHOUSE_HOST##\n    secretName: clickhouse" manifests/ingress/clickhouse.yaml
    sed -i -e "\$a\ \ tls:\n  - hosts:\n    - ##LOGHOUSE_HOST##\n    secretName: loghouse" manifests/ingress/loghouse.yaml
    sed -i -e "\$a\ \ tls:\n  - hosts:\n    - ##TABIX_HOST##\n    secretName: tabix" manifests/ingress/tabix.yaml
    # prepare url to clickhouse for loghouse
    sed -i -e "s/##CLICKHOUSE_HOST##/https:\/\/$CLICKHOUSE_HOST/g" manifests/loghouse/loghouse.yaml
  fi
  sed -i -e "s/##CLICKHOUSE_HOST##/$CLICKHOUSE_HOST/g" manifests/ingress/clickhouse.yaml
  sed -i -e "s/##LOGHOUSE_HOST##/$LOGHOUSE_HOST/g" manifests/ingress/loghouse.yaml
  sed -i -e "s/##TABIX_HOST##/$TABIX_HOST/g" manifests/ingress/tabix.yaml
  # set storage for clickhouse
  sed -i -e "s/##STORAGE_SIZE##/$STORAGE_SIZE/g" manifests/clickhouse/clickhouse.yaml
  sed -i -e "s/##STORAGE_CLASS_NAME##/$STORAGE_CLASS_NAME/g" manifests/clickhouse/clickhouse.yaml
  # set clickhouse password
  sed -i -e "s/##CLICKHOUSE_PASS_SHA256##/$CLICKHOUSE_PASS_SHA256/g" manifests/clickhouse/clickhouse-configmap.yaml
  sed -i -e "s/##CLICKHOUSE_PASS##/$CLICKHOUSE_PASS/g" manifests/clickhouse/clickhouse.yaml
  sed -i -e "s/##CLICKHOUSE_PASS##/$CLICKHOUSE_PASS/g" manifests/fluentd/fluentd-ds.yaml
  sed -i -e "s/##CLICKHOUSE_PASS##/$CLICKHOUSE_PASS/g" manifests/loghouse/loghouse.yaml
  # set clickhouse db
  sed -i -e "s/##CLICKHOUSE_DB##/$CLICKHOUSE_DB/g" manifests/clickhouse/clickhouse.yaml
  sed -i -e "s/##CLICKHOUSE_DB##/$CLICKHOUSE_DB/g" manifests/fluentd/fluentd-ds.yaml
  sed -i -e "s/##CLICKHOUSE_DB##/$CLICKHOUSE_DB/g" manifests/loghouse/loghouse.yaml
  # set clickhouse table
  sed -i -e "s/##K8S_LOGS_TABLE##/$K8S_LOGS_TABLE/g" manifests/clickhouse/clickhouse.yaml
  sed -i -e "s/##K8S_LOGS_TABLE##/$K8S_LOGS_TABLE/g" manifests/fluentd/fluentd-ds.yaml
  sed -i -e "s/##K8S_LOGS_TABLE##/$K8S_LOGS_TABLE/g" manifests/loghouse/loghouse.yaml
  # set storage for clickhouse
  if [ -n "$STORAGECLASS_USER_SECRET_VALUE" ] ; then
    sed -i -e "s/##STORAGECLASS_USER_SECRET_NAME##/$STORAGECLASS_USER_SECRET_NAME/" manifests/clickhouse/storage_secret.yaml
    sed -i -e "s/##STORAGECLASS_USER_SECRET_VALUE##/$STORAGECLASS_USER_SECRET_VALUE/" manifests/clickhouse/storage_secret.yaml
    sed -i -e "s/##STORAGE_SIZE##/$STORAGE_SIZE/g" manifests/clickhouse/clickhouse.yaml
    sed -i -e "s/##STORAGE_CLASS_NAME##/$STORAGE_CLASS_NAME/g" manifests/clickhouse/clickhouse.yaml
  fi
  $UPGRADE_SCRIPT
}

if [ "$MODE" == "install" ]
then
  KUBE_HOST="$1"
  if [ ! "$KUBE_HOST" ] ; then echo "KUBE_HOST arguments required. See '--help' for more information."; exit 1; fi
  kubectl get ns "$NAMESPACE" >/dev/null 2>&1 && FIRST_INSTALL="false"
  if [ "$FIRST_INSTALL" == "true" ]
  then
    install
  else
    echo "Namespace $NAMESPACE exists. Please, delete or run with the --upgrade option it to avoid shooting yourself in the foot."
  fi
elif [ "$MODE" == "upgrade" ]
then
  kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || (echo "Namespace '$NAMESPACE' does not exist. Please, install operator with '-i' option first." ; exit 1)
  upgrade
elif [ "$MODE" == "delete" ]
then
  kubectl delete clusterrole fluentd || true
  kubectl delete clusterrolebindings fluentd || true
  kubectl delete ns "$NAMESPACE" || true
fi

function cleanup {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
