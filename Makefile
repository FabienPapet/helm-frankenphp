.PHONY: unit-test lint yamllint validate helm-test install-kubeconform

# Kubernetes API version kubeconform validates examples against. Override on the CLI:
#   make validate KUBE_VERSION=1.31.0
KUBE_VERSION ?= 1.29.0

unit-test:
	cd charts/frankenphp; helm unittest .

lint:
	helm lint charts/frankenphp

yamllint:
	yamllint examples/ docs/ -c .yamllint

install-kubeconform:
	@VERSION=v0.6.4; \
	OS=$$(uname | tr '[:upper:]' '[:lower:]'); \
	ARCH=$$(uname -m); \
	[ "$$ARCH" = "x86_64" ] && ARCH="amd64"; \
	[ "$$ARCH" = "aarch64" ] && ARCH="arm64"; \
	URL="https://github.com/yannh/kubeconform/releases/download/$$VERSION/kubeconform-$$OS-$$ARCH.tar.gz"; \
	echo "Installing kubeconform from $$URL..."; \
	curl -L $$URL | tar xz kubeconform; \
	chmod +x kubeconform; \
	sudo mv kubeconform /usr/local/bin/

validate:
	@for file in examples/*.yaml; do \
		echo "Validating $$file with kubeconform..."; \
		helm template frankenphp ./charts/frankenphp -f $$file | kubeconform -summary -strict -ignore-missing-schemas -kubernetes-version $(KUBE_VERSION) || exit 1; \
	done

# Install the chart with the CI smoke values and run `helm test` against a running cluster.
helm-test:
	helm install smoke ./charts/frankenphp -f charts/frankenphp/ci/smoke-values.yaml \
		--create-namespace --namespace smoke --wait --timeout 3m
	helm test smoke --namespace smoke --logs
	helm uninstall smoke --namespace smoke
