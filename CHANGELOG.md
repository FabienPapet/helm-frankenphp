# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `podSecurityContext` and `containerSecurityContext` fields — inject security context into all workloads (deployment, workers, crons, jobs)
- `livenessProbe` and `readinessProbe` fields — configurable health probes for the main deployment and workers
- `autoscaling` section — HorizontalPodAutoscaler support for the main deployment (`autoscaling/v2`)
- Per-worker HPA via `autoscale`, `minReplicas`, `maxReplicas`, `targetCPUUtilizationPercentage`, and `targetMemoryUtilizationPercentage` fields on consumer entries
- `podDisruptionBudget` section — PodDisruptionBudget support with `minAvailable`/`maxUnavailable`
- Example `12-security.yaml` demonstrating security-hardened deployment

### Changed
- Worker `command` now uses `command + args` pattern instead of wrapping in `/bin/sh -c` array
- Deployment `spec.replicas` is omitted when `autoscaling.enabled: true` to allow HPA to manage replica count

## [0.3.0] - 2024

### Added
- Helm hooks support for jobs via `annotations` field

### Changed
- Harmonized command structure across jobs, crons, and workers for consistency

### Fixed
- Various template alignment and indentation issues

## [0.2.0] - 2024

### Added
- Generic `volumes` and `volumeMounts` support — inject Secrets, ConfigMaps, and PVCs into all pods
- Example `11-secrets-volumes.yaml` demonstrating volume injection
- Unit tests for volume and volumeMount management
- Artifact Hub badge in README

## [0.1.1] - 2024

### Added
- Initial public release published to Artifact Hub
- Main application Deployment with HTTP/HTTPS/metrics ports
- Workers (consumers) as separate Deployments
- CronJobs for scheduled tasks
- Jobs with Helm hook support
- Service, Ingress, and PodMonitor templates
- Custom PHP ini and Caddyfile injection
- ServiceAccount support
- 12 example configurations covering dev, production, HA, Symfony, and more
- CI/CD pipeline with helm-unittest, helm lint, kubeconform, and KinD integration tests
- Automated release pipeline via chart-releaser
