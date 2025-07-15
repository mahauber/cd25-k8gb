#!/bin/bash

az config set extension.use_dynamic_install=yes_without_prompt
az fleet get-credentials --resource-group rg-aks-fleetmanager --name fleetmanager

kubectl create namespace managed

helm repo add k8gb https://www.k8gb.io
helm repo update
helm install my-k8gb k8gb/k8gb --version 0.14.0 --namespace managed

# docs: https://learn.microsoft.com/en-us/azure/kubernetes-fleet/concepts-resource-propagation
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
    # cluster scoped resources need to be selected explicitly, wrapping in envelope objects is also possible https://learn.microsoft.com/en-us/azure/kubernetes-fleet/quickstart-envelope-reserved-resources
    - group: apiextensions.k8s.io
      version: v1
      kind: CustomResourceDefinition
      name: gslbs.k8gb.absa.oss
  policy:
    placementType: PickAll
EOF


# examples
# apiVersion: placement.kubernetes-fleet.io/v1
# kind: ClusterResourcePlacement
# metadata:
#   name: crp-fixed
# spec:
#   policy:
#     placementType: PickFixed
#     clusterNames:
#     - cluster1
#     - cluster2
#   resourceSelectors:
#     - group: ""
#       kind: Namespace
#       name: test-deployment
#       version: v1