# Multi-Environment Deployments

This guide explains how to manage multiple environments (development, staging, production) with the
FrankenPHP Helm chart using Helm's values file layering and standard GitOps patterns.

## Values File Layering

Helm allows you to supply multiple `-f` / `--values` files. Values are merged left-to-right, with
later files taking precedence. A common pattern is:

```
values/
  base.yaml        # shared across all environments
  dev.yaml         # development overrides
  staging.yaml     # staging overrides
  production.yaml  # production overrides
```

### base.yaml (shared defaults)

```yaml
image:
  repository: my-registry.example.com/my-app

service:
  create: true
  type: ClusterIP
  port: 80

env:
  - name: APP_NAME
    value: "my-app"

resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    memory: "256Mi"
```

### dev.yaml (development)

```yaml
image:
  tag: "dev-latest"

deployment:
  replicas: 1

env:
  - name: APP_ENV
    value: dev
  - name: APP_DEBUG
    value: "true"
  - name: SERVER_NAME
    value: ":80"
```

### staging.yaml

```yaml
image:
  tag: "1.2.3-rc1"

deployment:
  replicas: 2

env:
  - name: APP_ENV
    value: staging
  - name: APP_DEBUG
    value: "false"
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: staging-db-secret
        key: url
```

### production.yaml

```yaml
image:
  tag: "1.2.3"

deployment:
  replicas: 5

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70

podDisruptionBudget:
  enabled: true
  minAvailable: 2

terminationGracePeriodSeconds: 60

topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: frankenphp

env:
  - name: APP_ENV
    value: prod
  - name: APP_DEBUG
    value: "false"
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: production-db-secret
        key: url
```

## Deploying to Each Environment

```bash
# Development
helm upgrade --install my-app ./charts/frankenphp \
  -f values/base.yaml \
  -f values/dev.yaml \
  --namespace dev --create-namespace

# Staging
helm upgrade --install my-app ./charts/frankenphp \
  -f values/base.yaml \
  -f values/staging.yaml \
  --namespace staging --create-namespace

# Production
helm upgrade --install my-app ./charts/frankenphp \
  -f values/base.yaml \
  -f values/production.yaml \
  --namespace production --create-namespace
```

## Inline Value Overrides with `--set`

For one-off or CI/CD-driven overrides (e.g., deploying a specific image tag):

```bash
helm upgrade --install my-app ./charts/frankenphp \
  -f values/base.yaml \
  -f values/production.yaml \
  --set image.tag="$CI_COMMIT_SHA" \
  --namespace production
```

## Using Helm Secrets or External Secret Operators

For sensitive values (database URLs, API keys), avoid storing them in values files. Use one of:

- **[helm-secrets](https://github.com/jkroepke/helm-secrets)** — encrypts values files with SOPS/GPG
- **[External Secrets Operator](https://external-secrets.io/)** — syncs secrets from AWS Secrets Manager, HashiCorp Vault, etc. into Kubernetes Secrets, then reference them via `valueFrom.secretKeyRef`
- **[Sealed Secrets](https://sealed-secrets.netlify.app/)** — encrypts Kubernetes Secret manifests safe for Git storage

## GitOps with ArgoCD or Flux

Both ArgoCD and Flux support multi-environment Helm deployments natively:

### ArgoCD Application (per environment)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app-production
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/my-app
    targetRevision: main
    path: charts/frankenphp
    helm:
      valueFiles:
        - ../../values/base.yaml
        - ../../values/production.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Flux HelmRelease (per environment)

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: my-app
  namespace: production
spec:
  interval: 5m
  chart:
    spec:
      chart: ./charts/frankenphp
      sourceRef:
        kind: GitRepository
        name: my-app
  valuesFrom:
    - kind: ConfigMap
      name: my-app-base-values
    - kind: ConfigMap
      name: my-app-production-values
    - kind: Secret
      name: my-app-production-secrets
      valuesKey: values.yaml
```

## Tip: Preview Rendered Manifests

Before deploying, preview the final manifests with `helm template`:

```bash
helm template my-app ./charts/frankenphp \
  -f values/base.yaml \
  -f values/production.yaml \
  --namespace production
```

This renders all Kubernetes resources without contacting the cluster, useful for reviewing changes
in CI/CD pipelines or pull request reviews.
