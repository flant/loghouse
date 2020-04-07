<p align="center">
  <a href="https://github.com/flant/loghouse"><img src="https://cdn.rawgit.com/flant/loghouse/master/docs/logo.png" style="max-height:100%;" height="300"></a>
</p>

___


[Loghouse](https://github.com/flant/loghouse) is a ready to use log management solution for Kubernetes. Efficiently store big amounts of your logs (in [ClickHouse](https://github.com/yandex/ClickHouse) database), process them using a simple [query language](https://github.com/flant/loghouse/blob/master/docs/en/query-language.md) and monitor them online through web UI. Easy and quick to deploy in an already functioning Kubernetes cluster.

# Installation

To install loghouse, you need to use [Helm](https://github.com/kubernetes/helm). Minimal kubernetes cluster version is **>=1.9**. Also, it is considered that [cert-manager](https://github.com/jetstack/cert-manager) is already installed in your cluster.

The whole process is as simple as these two steps:

1. Add loghouse charts:
```
# helm repo add loghouse https://flant.github.io/loghouse/charts/
```

2. Install a chart.

2.1. Easy way:

```
# helm fetch loghouse/loghouse --untar
# vim loghouse/values.yaml
# helm install --namespace loghouse -n loghouse loghouse
```

Note: use `--timeout 1200` flag in case slow image pulling.

2.2. Using specific parameters *(check variables in chart's [values.yaml](charts/loghouse/values.yaml) — not documented yet)*:

```
# helm install -n loghouse loghouse/loghouse --set 'param=value' ...
```

Web UI (loghouse-dashboard) will be reachable via address specified in values.yaml config as ```loghouse_host```. You'll be prompted by basic authorization generated via htpasswd and configured in ```auth``` parameter of your values.yaml.

> To clean old logs in cron, you can use a script in this [issue](https://github.com/flant/loghouse/issues/42).

