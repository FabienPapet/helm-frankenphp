# Advanced Features

FrankenPHP's Helm Chart is designed to handle more than just your main web application. It includes built-in support for background workers, scheduled tasks, and lifecycle jobs.

## Workers (Consumers)

Workers are long-running processes used to handle asynchronous tasks (e.g., message queues like Symfony Messenger). Each worker is deployed as a separate Kubernetes Deployment.

### Configuration

Add a `consumers` list to your `values.yaml`:

```yaml
consumers:
  - name: "async-messages"
    command: "php bin/console messenger:consume async"
    replicas: 2
    resources:
      limits:
        memory: "256Mi"
```

### Key Parameters for Workers:
- `name`: **Required**. Unique name for the worker (used in the Deployment name).
- `command`: **Required**. The command to execute.
- `replicas`: Number of pod instances (optional, defaults to 1 if not specified).
- `resources`: Resource requests and limits (defaults to global `resources` if not set).

## Cron Jobs

Scheduled tasks are managed via Kubernetes `CronJob` resources.

### Configuration

Add a `crons` list to your `values.yaml`:

```yaml
crons:
  - name: "cleanup-db"
    schedule: "0 2 * * *"
    command: "php bin/console app:cleanup"
    successfulJobsHistoryLimit: 1
    failedJobsHistoryLimit: 3
```

### Key Parameters for Crons:
- `name`: **Required**. Unique name for the cron job.
- `schedule`: **Required**. Standard crontab expression.
- `command`: **Required**. The command to execute (run within a shell).
- `concurrencyPolicy`: Controls how concurrent executions are handled. Options:
  - `Allow` (default): Allows concurrent jobs to run
  - `Forbid`: Prevents concurrent runs; new job is skipped if previous is still running
  - `Replace`: Cancels currently running job and replaces it with a new one
- `restartPolicy`: Default is `Never`.

## Jobs & Helm Hooks

Lifecycle jobs allow you to run one-off commands during chart installation or upgrade (e.g., database migrations).

### Configuration

Add a `jobs` list to your `values.yaml`:

```yaml
jobs:
  - name: "migrations"
    command: "php bin/console doctrine:migrations:migrate --no-interaction"
    restartPolicy: "OnFailure"  # or "Never"
    annotations:
      "helm.sh/hook": post-install,post-upgrade
      "helm.sh/hook-delete-policy": before-hook-creation
```

### Key Parameters for Jobs:
- `name`: **Required**. Unique name for the job.
- `command`: **Required**. The command to execute.
- `restartPolicy`: Restart policy for the job. Options:
  - `OnFailure`: Restart the container if it fails
  - `Never`: Never restart the container
- `annotations`: Helm hook annotations to control when the job runs.

### Why use Helm Hooks?
By using annotations like `"helm.sh/hook": post-install`, you ensure that migrations only run after the application pods are ready (or vice versa, depending on the hook type).

## Global vs Local settings

- **Environment Variables**: The `env` list defined at the root of `values.yaml` is injected into **all** pods (Main application, Workers, Crons, and Jobs).
- **PHP Config**: The `php.ini` defined globally is also shared across all these components.
- **Service Account**: All components share the same ServiceAccount configuration.

## Autoscaling (HPA)

The chart supports Kubernetes `HorizontalPodAutoscaler` (autoscaling/v2) for the main deployment and individual workers.

### Main Deployment HPA

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 75
```

> **Note:** When `autoscaling.enabled: true`, the `spec.replicas` field is omitted from the Deployment to avoid conflicts with the HPA. You must have [metrics-server](https://github.com/kubernetes-sigs/metrics-server) installed in your cluster.

### Worker HPA

Each worker can independently enable HPA via the `autoscale` flag:

```yaml
consumers:
  - name: "queue"
    command: "php bin/console messenger:consume async"
    autoscale: true
    minReplicas: 1
    maxReplicas: 5
    targetCPUUtilizationPercentage: 80
```

## Pod Disruption Budget

To ensure availability during voluntary disruptions (e.g., node maintenance), enable the PodDisruptionBudget:

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 2  # must be less than deployment.replicas
```

Or use `maxUnavailable` instead of `minAvailable`:

```yaml
podDisruptionBudget:
  enabled: true
  maxUnavailable: 1
```

> **Note:** A PDB only makes sense when you have more than 1 replica. Ensure `minAvailable` is less than your replica count, otherwise node drains will block.

## Security Context

You can configure pod- and container-level security contexts to harden your workloads:

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

containerSecurityContext:
  allowPrivilegeEscalation: false
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
      - ALL
```

Security contexts are applied to all workloads: the main deployment, workers, crons, and jobs.

> **Note:** `readOnlyRootFilesystem: true` may cause issues with FrankenPHP/Caddy as it writes temporary files. Test carefully before enabling this in production.

## Health Probes

Configure liveness and readiness probes to enable Kubernetes self-healing and proper traffic management:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3
```

Probes are applied to both the main deployment and workers. By default, no probes are configured.

### Startup Probe

For slow-starting applications, add a startup probe to delay liveness/readiness checks until boot completes:

```yaml
startupProbe:
  httpGet:
    path: /
    port: http
  failureThreshold: 30   # 30 × 10s = 5 minutes max startup time
  periodSeconds: 10
```

See `examples/13-startup-probe.yaml` for a full example.
