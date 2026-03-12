# FrankenPHP Helm Chart

[![CI](https://github.com/FabienPapet/helm-frankenphp/actions/workflows/ci.yaml/badge.svg)](https://github.com/FabienPapet/helm-frankenphp/actions/workflows/ci.yaml)
[![Helm Release](https://github.com/FabienPapet/helm-frankenphp/actions/workflows/release.yaml/badge.svg)](https://github.com/FabienPapet/helm-frankenphp/actions/workflows/release.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/frankenphp)](https://artifacthub.io/packages/search?repo=frankenphp)
This repository contains a Helm chart to deploy docker images built with [FrankenPHP](https://frankenphp.dev/), the modern PHP application server built on top of Caddy, on Kubernetes.

> [!TIP]
> **Check out the [examples](examples) for real-world use cases.**

## Features

- **FrankenPHP**: High-performance PHP server with Caddy.
- **Workers**: Easily deploy Messenger/AMQP workers.
- **CronJobs**: Manage scheduled tasks within the same chart.
- **PHP Config**: Inject custom `php.ini` via ConfigMaps.
- **Caddy Config**: Override the `Caddyfile` completely.
- **Jobs/Hooks**: Run migrations or one-off tasks using Helm hooks.
- **Monitoring**: Integrated `PodMonitor` for Prometheus (requires Prometheus Operator).
- **Scheduling**: Support for `nodeSelector`, `affinity`, and `tolerations` for all pods.
- **Volume Management**: Mount any Kubernetes volume (Secrets, ConfigMaps, PVCs) into all pods.

## Examples

Some configuration examples are available in the [examples/](examples/) directory:

- [Symfony App with Migrations](examples/10-symfony-app.yaml)
- [Custom Caddyfile](examples/04-custom-caddy.yaml)
- [Workers](examples/05-workers.yaml)
- [CronJobs](examples/06-cronjobs.yaml)
- [Jobs](examples/07-jobs.yaml)
- [High Availability](examples/08-high-availability.yaml)
- [Production Setup](examples/02-production.yaml)
- [Secrets & Volume Mounts](examples/11-secrets-volumes.yaml)

## Installation

### Quick Start

```bash
# create values file
cat > values.yaml <<EOF
image:
  repository: dunglas/frankenphp
  tag: "latest"

deployment:
  replicas: 1
EOF
# install from repository
helm repo add frankenphp https://fabienpapet.github.io/helm-frankenphp/
helm install my-app frankenphp/frankenphp -f values.yaml
```

## Development

### Volume Management

The chart supports mounting arbitrary volumes (Kubernetes Secrets, ConfigMaps, PersistentVolumeClaims, etc.) into **all pods** (deployment, workers, crons, jobs) via `volumes` and `volumeMounts`.

> [!IMPORTANT]
> Kubernetes Secrets must be created **before** installing or upgrading the chart. The chart does not create secrets for you — this keeps sensitive data out of Helm values and release history.

**Example: Symfony decrypt key**

1. Create the Kubernetes Secret:

```bash
kubectl create secret generic symfony-secrets \
  --from-file=prod.decrypt.private.php=config/secrets/prod/prod.decrypt.private.php
```

2. Reference it in your `values.yaml`:

```yaml
volumes:
  - name: symfony-decrypt-key
    secret:
      secretName: symfony-secrets
      items:
        - key: prod.decrypt.private.php
          path: prod.decrypt.private.php

volumeMounts:
  - name: symfony-decrypt-key
    mountPath: /app/config/secrets/prod/prod.decrypt.private.php
    subPath: prod.decrypt.private.php
    readOnly: true
```

See [examples/11-secrets-volumes.yaml](examples/11-secrets-volumes.yaml) for a complete example.

### Run Unit Tests & Validation

This chart uses the `helm-unittest` plugin and `kubeconform`.

```bash
# Unit tests
make unit-test

# Manifest validation (requires kubeconform)
make validate
```

## 👥 Contributing

Contributions are welcome! Please have a look at the [contributing guidelines](CONTRIBUTING.md) before submitting a pull request.
