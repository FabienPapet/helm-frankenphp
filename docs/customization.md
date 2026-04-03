# Customization Guide

FrankenPHP is highly customizable. This chart allows you to easily inject your own PHP and Caddy configurations.

## PHP Configuration (`php.ini`)

You can provide custom PHP settings via the `php.ini` key in `values.yaml`. These settings are injected into a file named `99-custom.ini` inside the `/usr/local/etc/php/conf.d/` directory.

### Example

```yaml
php:
  ini: |
    memory_limit = 512M
    max_execution_time = 60
    display_errors = Off
```

This configuration is shared across the main application deployment, workers, crons, and jobs.

## Caddy Configuration (`Caddyfile`)

FrankenPHP uses Caddy as its web server. If the default configuration doesn't suit your needs, you can provide a full `Caddyfile`.

### Example

```yaml
caddyfile: |
  {
      frankenphp
      order php_server before file_server
  }
  
  :80 {
      root * /app/public
      encode zstd br gzip
      php_server
      file_server
  }
```

### Important Notes:
- When providing a custom `Caddyfile`, make sure to include the `frankenphp` global option.
- The default `Caddyfile` is baked into the FrankenPHP image. The Helm chart only overwrites it if the `caddyfile` key is provided in `values.yaml`.

## Environment Variables

For simpler customizations, you can use environment variables. FrankenPHP and many PHP frameworks (like Symfony or Laravel) use them for runtime configuration.

```yaml
env:
  - name: APP_ENV
    value: prod
  - name: MY_CUSTOM_VARIABLE
    value: "some-value"
```

## Security Context

Harden your containers with pod- and container-level security contexts:

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

Both contexts are optional and empty by default to preserve backwards compatibility with all FrankenPHP images.

## Health Probes

Add liveness and readiness probes to improve reliability and traffic management:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 5
  periodSeconds: 10
```

You can also use `exec` or `tcpSocket` probe types. Probes are applied to the main deployment and all workers.

## Startup Probe

For applications with long startup times (e.g. Symfony cache warmup, Laravel bootstrap), use a startup
probe to prevent premature liveness/readiness failures during the boot phase:

```yaml
# Allow up to 5 minutes for the app to start (30 × 10s)
startupProbe:
  httpGet:
    path: /
    port: http
  failureThreshold: 30
  periodSeconds: 10
```

While the startup probe is active, liveness and readiness probes are paused. Only after the startup
probe succeeds do the other probes take over.
