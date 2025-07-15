#!/bin/bash

az config set extension.use_dynamic_install=yes_without_prompt
az fleet get-credentials --resource-group rg-aks-fleetmanager --name fleetmanager

kubectl create namespace managed

helm repo add k8gb https://www.k8gb.io
helm repo update
helm install my-k8gb k8gb/k8gb --version 0.14.0 --namespace managed

kubectl apply -f - <<EOF
apiVersion: placement.kubernetes-fleet.io/v1
kind: ClusterResourcePlacement
metadata:
  name: managed
spec:
  resourceSelectors:
    - group: ""
      kind: Namespace
      version: v1
      name: managed
  policy:
    placementType: PickAll
EOF