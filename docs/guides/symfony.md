# Symfony Deployment Guide

Deploying a Symfony application with FrankenPHP and Helm is straightforward. This guide covers specific configurations for databases, migrations, and the worker mode.

## Base Configuration

Ensure your environment variables are correctly set for Symfony:

```yaml
env:
  - name: APP_ENV
    value: prod
  - name: APP_SECRET
    valueFrom:
      secretKeyRef:
        name: symfony-secrets
        key: app-secret
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: database-secrets
        key: url
```

## Running Migrations

Using Helm Hooks, you can automatically run migrations during deployment. This ensures the database schema is updated before (or while) the new version of the app starts.

```yaml
jobs:
  - name: "migrations"
    command: "php bin/console doctrine:migrations:migrate --no-interaction"
    annotations:
      "helm.sh/hook": post-install,post-upgrade
      "helm.sh/hook-delete-policy": before-hook-creation
```

## Using Symfony Messenger

If you use asynchronous messages, you can deploy workers as side-deployments:

```yaml
consumers:
  - name: "messages"
    command: "php bin/console messenger:consume async"
    replicas: 2
```

## PHP Configuration for Symfony

Recommended PHP settings for production Symfony applications:

```yaml
php:
  ini: |
    opcache.preload = /app/config/preload.php
    opcache.validate_timestamps = 0
    memory_limit = 256M
```

## Full Example

Check out the [complete Symfony example](../examples/10-symfony-app.yaml) in the repository for a combined configuration.
