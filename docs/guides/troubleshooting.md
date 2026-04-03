# Troubleshooting Guide

This guide covers common issues when deploying FrankenPHP with this Helm chart.

## Pod Fails to Start (`CrashLoopBackOff`)

**Symptoms:** Pod repeatedly restarts, status shows `CrashLoopBackOff`.

**Steps to diagnose:**
```bash
# Check pod status and events
kubectl describe pod <pod-name>

# View container logs
kubectl logs <pod-name> --previous
```

**Common causes:**
- **Wrong image tag** — ensure `image.repository` and `image.tag` are correct and the image is accessible.
- **Missing environment variable** — your application may require specific env vars (e.g., `DATABASE_URL`). Add them to `env:` or inject via a Secret.
- **Security context too restrictive** — if you set `containerSecurityContext.runAsNonRoot: true` but your image runs as root by default, the container will fail. Either change the image or set `runAsUser` to the appropriate UID.
- **Port conflict** — if `SERVER_NAME` is set to bind on a privileged port (< 1024) and the container runs as non-root, the bind will fail. Use `:8080` or configure a higher port.

---

## OOMKilled (Out of Memory)

**Symptoms:** Pod is terminated with `OOMKilled`.

**Fix:** Increase memory limits and/or adjust PHP's `memory_limit`:

```yaml
resources:
  limits:
    memory: "512Mi"

php:
  ini: |
    memory_limit = 256M
```

---

## Worker Not Starting

**Symptoms:** Worker Deployment exists but pods are not running.

**Check:**
```bash
kubectl describe deployment <release-name>-worker-<name>
kubectl logs <worker-pod-name>
```

**Common causes:**
- `command` is invalid — the command is executed via `/bin/sh -c`. Verify it works in your container locally.
- The worker's preStop hook creates `/tmp/kill_me`. If your application checks this file to exit, ensure your command handles it properly.

---

## Custom PHP ini Not Applied

**Symptoms:** PHP settings (e.g., `memory_limit`) appear unchanged.

**Verify the ConfigMap was created:**
```bash
kubectl get configmap <release-name>-php-ini -o yaml
```

**Check the volume mount:**
```bash
kubectl exec <pod-name> -- cat /usr/local/etc/php/conf.d/99-custom.ini
```

The file should contain your settings. If it doesn't, ensure `php.ini` is set in `values.yaml`.

---

## Ingress / TLS Not Working

**Symptoms:** Application is unreachable via Ingress, or HTTPS certificate is not issued.

**Check the Ingress resource:**
```bash
kubectl describe ingress <release-name>
```

**Common causes:**
- `ingress.enabled` is `false` (or not set) — set `ingress.enabled: true`.
- Wrong `ingress.className` — set it to your installed Ingress controller (e.g., `nginx`, `traefik`).
- cert-manager not installed — TLS via cert-manager requires cert-manager to be running. Check with `kubectl get pods -n cert-manager`.
- Missing annotation — for cert-manager, ensure you have:
  ```yaml
  ingress:
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
  ```

---

## HPA Not Scaling

**Symptoms:** Pod count stays fixed despite high CPU/memory usage.

**Check:**
```bash
kubectl get hpa <release-name>
kubectl describe hpa <release-name>
```

**Common causes:**
- **metrics-server not installed** — HPA requires the Kubernetes metrics-server. Install it or check:
  ```bash
  kubectl top pods
  ```
- **No resource requests set** — HPA calculates utilization based on resource requests. Ensure you have `resources.requests.cpu` defined.
- `autoscaling.enabled` is `false` — verify your values override has `autoscaling.enabled: true`.

---

## PodDisruptionBudget Blocking Node Drain

**Symptoms:** `kubectl drain` hangs or times out.

**Cause:** If `podDisruptionBudget.minAvailable` equals the total number of replicas, Kubernetes cannot evict any pod.

**Fix:** Ensure `minAvailable` is less than `deployment.replicas`:
```yaml
deployment:
  replicas: 3

podDisruptionBudget:
  enabled: true
  minAvailable: 2   # at least 1 pod can be evicted
```

---

## Image Pull Errors (`ImagePullBackOff`)

**Symptoms:** Pod stuck in `ImagePullBackOff`.

**Diagnose:**
```bash
kubectl describe pod <pod-name>
```

**Fix:** If using a private registry, configure `image.pullSecrets`:
```yaml
image:
  repository: my-private-registry.example.com/my-app
  tag: "1.0.0"
  pullSecrets:
    - name: my-registry-secret
```

Create the secret with:
```bash
kubectl create secret docker-registry my-registry-secret \
  --docker-server=my-private-registry.example.com \
  --docker-username=<username> \
  --docker-password=<password>
```

---

## Worker Not Processing Messages

**Symptoms:** Messages pile up in the queue; consumers report no activity or exit immediately.

**Check worker deployment status:**
```bash
kubectl get deployments -l app.kubernetes.io/name=frankenphp
kubectl logs -l app=<release-name>-worker-<consumer-name> --tail=50
```

**Common causes:**

- **Wrong command** — verify the command in `consumers[].command` is correct for your queue driver:
  ```yaml
  consumers:
    - name: queue
      command: "php bin/console messenger:consume async --time-limit=3600"
  ```

- **Worker exiting too fast** — some workers exit after processing a batch. This is fine if you have `restartPolicy: Always` (default). Check the pod restart count:
  ```bash
  kubectl get pods -l app=<release-name>-worker-<consumer-name>
  ```

- **Insufficient replicas** — scale up workers:
  ```yaml
  consumers:
    - name: queue
      command: "php bin/console messenger:consume async"
      replicas: 3
  ```

- **Missing terminationGracePeriodSeconds** — workers processing long tasks may be killed mid-flight during upgrades. Increase the grace period:
  ```yaml
  terminationGracePeriodSeconds: 120
  ```

- **Worker needs database connection before starting** — use an init container to wait for readiness:
  ```yaml
  initContainers:
    - name: wait-for-db
      image: busybox
      command: ['sh', '-c', 'until nc -z db 5432; do sleep 2; done']
  ```

---

## CronJob Not Running on Schedule

**Symptoms:** CronJob exists but no Jobs are created at the expected time.

**Check:**
```bash
kubectl get cronjobs
kubectl describe cronjob <release-name>-<cron-name>
kubectl get jobs --sort-by=.metadata.creationTimestamp
```

**Common causes:**

- **Timezone issues** — Kubernetes CronJob schedules use UTC by default. Adjust your schedule accordingly.
- **concurrencyPolicy: Forbid blocking** — if a previous run is still active and `concurrencyPolicy: Forbid` is set, no new job will start. Use `concurrencyPolicy: Replace` or increase the job timeout.
- **failedJobsHistoryLimit too low** — if set to `0`, failed jobs are immediately deleted, making debugging harder. Keep the default of `3`.
- **Wrong schedule syntax** — validate your cron expression using a tool like [crontab.guru](https://crontab.guru/).
