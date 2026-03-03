.PHONY: unit-test lint validate install-kubeconform

unit-test:
	cd charts/frankenphp; helm unittest .

lint:
	helm lint charts/frankenphp

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
		helm template frankenphp ./charts/frankenphp -f $$file | kubeconform -summary -strict -ignore-missing-schemas -kubernetes-version 1.29.0 || exit 1; \
	done
