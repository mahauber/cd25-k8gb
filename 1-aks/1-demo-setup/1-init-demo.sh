#!/bin/bash

set -euo pipefail

# Set variables
RESOURCE_GROUP="rg-aks-gwc"
CLUSTERS=("aks-gwc" "aks-sdc")
NAMESPACE="managed"

for CLUSTER_NAME in "${CLUSTERS[@]}"; do
  echo "Setting up cluster: $CLUSTER_NAME"

  # Get credentials for the AKS cluster
  az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

  # Create the managed namespace if it doesn't exist
  kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE

  # Add and update Helm repositories (only once)
  if [[ "$CLUSTER_NAME" == "${CLUSTERS[0]}" ]]; then
    helm repo add k8gb https://www.k8gb.io || true
    helm repo add podinfo https://stefanprodan.github.io/podinfo || true
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
    helm repo update
  fi

  # Install NGINX Ingress Controller
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace $NAMESPACE \
    --version 4.13.0 \
    -f nginxingress-helmchart.yaml

  # Install k8gb
  helm upgrade --install k8gb k8gb/k8gb \
    --namespace $NAMESPACE \
    --version 0.14.0 \
    -f k8gb-helmchart.yaml

  # Install podinfo
  helm upgrade --install podinfo podinfo/podinfo \
    --namespace $NAMESPACE \
    --version 6.9.1 \
    -f podinfo-helmchart.yaml

  echo "k8gb demo setup complete on cluster $CLUSTER_NAME in namespace $NAMESPACE."
done