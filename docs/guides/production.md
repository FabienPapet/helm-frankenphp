# Production Best Practices

Deploying to production requires careful consideration of scaling, resources, and security.

## High Availability

Always run at least 2 or 3 replicas of your application to ensure availability during node maintenance or failures.

```yaml
deployment:
  replicas: 3
```

## Resource Management

Define CPU and Memory requests and limits to help Kubernetes schedule your pods effectively and prevent one pod from consuming all node resources.

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    memory: "256Mi"
```

## Security

- Use a specific image tag (e.g., `1.1.0-php8.3`) instead of `latest` to ensure reproducibility.
- If your registry requires authentication, configure `imagePullSecrets`.
- Harden your containers with security contexts:

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
  capabilities:
    drop:
      - ALL
```

> **Note:** `readOnlyRootFilesystem: true` may cause issues with FrankenPHP/Caddy. Test carefully.

## Pod Disruption Budget

For production, configure a PodDisruptionBudget to maintain availability during node maintenance:

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 2  # must be less than deployment.replicas
```

## Autoscaling

Use HPA to automatically scale the deployment based on CPU/memory:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

> **Requirement:** [metrics-server](https://github.com/kubernetes-sigs/metrics-server) must be installed. Also set `resources.requests.cpu` — HPA calculates utilization relative to requests.

## Health Probes

Add probes to enable Kubernetes self-healing and proper traffic steering:

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

## Networking

Enable TLS for your Ingress to secure your application.

```yaml
ingress:
  enabled: true
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com
```

## Monitoring

If you have Prometheus Operator installed, enable the `PodMonitor` to collect performance metrics.

```yaml
monitoring:
  enabled: true
```
