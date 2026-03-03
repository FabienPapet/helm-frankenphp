# Examples Index

The `examples/` directory contains various configuration files to help you get started with common use cases. You can use these files with the `-f` flag of the `helm install` or `helm upgrade` commands.

## Basic Scenarios

- **[00-defaults.yaml](../examples/00-defaults.yaml)**: The minimal configuration possible. Relies almost entirely on default values.
- **[01-development.yaml](../examples/01-development.yaml)**: Tailored for local or development environments (e.g., `APP_ENV=dev`, `Always` pull policy).
- **[02-production.yaml](../examples/02-production.yaml)**: Production-ready settings with multiple replicas and resource limits.

## Customization

- **[03-custom-php.yaml](../examples/03-custom-php.yaml)**: Demonstrates how to inject a custom `php.ini`.
- **[04-custom-caddy.yaml](../examples/04-custom-caddy.yaml)**: Shows how to provide a complete custom `Caddyfile`.

## Advanced Components

- **[05-workers.yaml](../examples/05-workers.yaml)**: Highlights the `consumers` configuration to deploy background workers.
- **[06-cronjobs.yaml](../examples/06-cronjobs.yaml)**: Demonstrates how to schedule recurring tasks via `crons`.
- **[10-symfony-app.yaml](../examples/10-symfony-app.yaml)**: A specialized example for Symfony applications, including jobs/hooks for migrations and worker configuration.

## Networking and Scaling

- **[07-ingress-tls.yaml](../examples/07-ingress-tls.yaml)**: Shows how to configure Ingress with TLS certificates and a specific host.
- **[08-high-availability.yaml](../examples/08-high-availability.yaml)**: Focuses on high availability with multiple replicas and resource optimization.

## Full Stack

- **[09-complete-stack.yaml](../examples/09-complete-stack.yaml)**: A complex example combining Ingress, customized PHP/Caddy, Workers, and Resource limits.

---

### How to use an example:

```bash
helm install my-release ./charts/frankenphp -f examples/01-development.yaml
```
