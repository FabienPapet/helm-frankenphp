# Getting Started

This guide will walk you through the installation and basic configuration of the FrankenPHP Helm Chart.

## Prerequisites

- A Kubernetes cluster (v1.23+)
- Helm 3.0+
- (Optional) `kubectl` configured to your cluster.

## Installation

### Adding the Repository

Currently, the chart is available on GitHub. You can install it directly from the source or via our Helm repository (if configured):

```bash
# Via GitHub (source)
git clone https://github.com/FabienPapet/helm-frankenphp.git
cd helm-frankenphp
helm install my-release ./charts/frankenphp
```

### Basic Usage

By default, the chart will deploy 3 replicas of the official FrankenPHP image listening on port 80.

```bash
helm install my-app ./charts/frankenphp \
  --set image.tag=latest \
  --set service.port=80
```

## Accessing the Application

If you have an Ingress controller installed (like Nginx), you can enable the Ingress in your `values.yaml`:

```yaml
ingress:
  enabled: true
  hosts:
    - host: my-app.example.com
      paths:
        - path: /
          pathType: Prefix
```

Deploying with these values:
```bash
helm install my-app ./charts/frankenphp -f my-values.yaml
```

## Next Steps

- Explore [Configuration Reference](configuration.md) to see all available options.
- Learn about [Workers and CronJobs](features.md).
- Check out our [Examples](examples.md) for more complex setups.
