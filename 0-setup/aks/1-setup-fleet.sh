#!/bin/bash

az config set extension.use_dynamic_install=yes_without_prompt
az fleet get-credentials --resource-group rg-aks-fleetmanager --name fleetmanager

kubectl create namespace managed

helm repo add fluxcd-community https://fluxcd-community.github.io/helm-charts
helm repo update
helm upgrade --install my-flux2 fluxcd-community/flux2 --version 2.16.2 --namespace managed

kubectl apply -f ./manifests/k8gb-helmchart.yaml
kubectl apply -f ./manifests/fluxcd-placement.yaml