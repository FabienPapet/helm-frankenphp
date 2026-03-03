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
