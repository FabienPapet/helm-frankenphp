# Contributing to FrankenPHP Helm Chart

First off, thank you for considering contributing to this chart!

## How to Contribute

1. **Fork the repository** on GitHub.
2. **Clone your fork** locally.
3. **Create a branch** for your feature or bug fix.
4. **Develop and test** your changes.
    - Run `make unit-test` to ensure no regressions.
    - Run `make lint` to check for chart issues.
    - Add unit tests for new features.
5. **Update documentation**: If you change `values.yaml`, run `make docs` (requires `helm-docs`) or ensure the README is updated.
6. **Commit and push** your changes to your fork.
7. **Open a Pull Request** against the `main` branch.

## Requirements

- [Helm](https://helm.sh/docs/intro/install/)
- [helm-unittest plugin](https://github.com/helm-unittest/helm-unittest)
- [kubeconform](https://github.com/yannh/kubeconform) (optional, for validation)
- [helm-docs](https://github.com/norwoodj/helm-docs) (optional, for documentation)

## Project Standards

- Keep templates clean and DRY.
- Use helpers for repetitive labels and names.
- Always update `values.schema.json` when adding/modifying `values.yaml`.
- Follow [Semantic Versioning](https://semver.org/).
