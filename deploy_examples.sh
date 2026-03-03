#!/bin/bash
EXAMPLES=(
  "01-development.yaml frankenphp-dev"
  "02-production.yaml frankenphp-prod"
  "03-custom-php.yaml frankenphp-custom-php"
  "04-custom-caddy.yaml frankenphp-custom-caddy"
  "05-workers.yaml frankenphp-workers"
  "06-cronjobs.yaml frankenphp-cronjobs"
  "07-ingress-tls.yaml frankenphp-ingress"
  "08-high-availability.yaml frankenphp-ha"
  "09-complete-stack.yaml frankenphp-complete"
  "10-symfony-app.yaml frankenphp-symfony"
)

for pair in "${EXAMPLES[@]}"; do
  file=$(echo $pair | cut -d' ' -f1)
  ns=$(echo $pair | cut -d' ' -f2)
  
  echo "--- Deploying $file to namespace $ns ---"
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
  helm template frankenphp ./charts/frankenphp -f "examples/$file" --namespace "$ns" | kubectl apply -f - -n "$ns"
  echo "Done with $file"
  echo ""
done
