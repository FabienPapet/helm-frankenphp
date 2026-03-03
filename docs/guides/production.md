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
