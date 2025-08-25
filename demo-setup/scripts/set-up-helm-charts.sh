#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

if ! command -v az &> /dev/null; then
  echo "Azure CLI (az) not found. Please install it before running this script."
  exit 1
fi

if ! command -v helm &> /dev/null; then
  echo "Helm not found. Please install it before running this script."
  exit 1
fi

if ! command -v kubectl &> /dev/null; then
  echo "kubectl not found. Please install it before running this script."
  exit 1
fi

if ! command -v kubelogin &> /dev/null; then
  echo "kubelogin not found. Please install it before running this script."
  exit 1
fi

# Update Helm repositories
helm repo add k8gb https://www.k8gb.io
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

for CLUSTER_NAME in $CLUSTERS; do
  echo "#################################"
  echo "## Setting up cluster: $CLUSTER_NAME ##"
  echo "#################################"

  # Get credentials for the AKS cluster
  az aks get-credentials --resource-group $CLUSTER_NAME --name $CLUSTER_NAME --subscription $TF_VAR_subscription_id --overwrite-existing
  kubelogin convert-kubeconfig -l azurecli

  # Getting the cluster geo tags & location
  CURRENT_CLUSTER_LOCATION=$(az aks show --resource-group $CLUSTER_NAME --name $CLUSTER_NAME --query location -o tsv)
  CLEAN_ALL_CLUSTER_LOCATIONS=$(comm -23 <(az aks list --query "[].location" -o tsv | sort) <(echo $CURRENT_CLUSTER_LOCATION | sort))
  CLEAN_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS=$(echo $CLEAN_ALL_CLUSTER_LOCATIONS | paste -sd,)
  CLEAN_ESCAPED_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS="${CLEAN_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS//,/\\,}" # escape commas for Helm values

  # Install NGINX Ingress Controller
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --version 4.13.0 \
    --create-namespace \
    --set udp.53="k8gb/k8gb-coredns:53" \
    --namespace ingress-nginx \
    -f $SCRIPT_DIR/../helm-values/ingress-nginx/values.yaml

  kubectl create ns k8gb --dry-run=client -o yaml | kubectl apply -f -

  # create secret for reference to managed identity to access public dns zone https://github.com/k8gb-io/external-dns/blob/master/docs/tutorials/azure.md
  kubectl apply -f - <<END
apiVersion: v1
kind: Secret
metadata:
  name: external-dns-secret-azure
  namespace: k8gb
type: Opaque
data:
  azure.json: $(cat <<EOF | base64 | tr -d '\n'
{
  "tenantId": "$TENANT_ID",
  "subscriptionId": "$TF_VAR_subscription_id",
  "resourceGroup": "$DNS_ZONE_RESOURCE_GROUP",
  "useManagedIdentityExtension": true
}
EOF
)
END

  sleep 10 # waiting for ingress-nginx-controller-admission

  # Install podinfo
  helm upgrade --install podinfo podinfo/podinfo \
    --namespace default \
    --version 6.9.1 \
    --set ui.message="$CLUSTER_NAME" \
    --set ingress.hosts[0].host="podinfo.$LOAD_BALANCED_ZONE" \
    --set-string "ingress.annotations.k8gb\.io/primary-geotag=$PRIMARY_GEO_TAG" \
    --set-string "ingress.additionalLabels.k8gb\.io/ip-source=true" \
    --set ui.logo="https://dummyimage.com/600x400/fab41e/3C4146&text=$CURRENT_CLUSTER_LOCATION" \
    -f $SCRIPT_DIR/../helm-values/podinfo/values.yaml


  # Install k8gb
  helm upgrade --install k8gb k8gb/k8gb \
    --namespace k8gb \
    --create-namespace \
    --version 0.15.0 \
    --set "k8gb.clusterGeoTag=$CURRENT_CLUSTER_LOCATION" \
    --set "k8gb.extGslbClustersGeoTags=$CLEAN_ESCAPED_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS" \
    --set "k8gb.dnsZones[0].loadBalancedZone=$LOAD_BALANCED_ZONE" \
    --set "k8gb.dnsZones[0].parentZone=$TF_VAR_dns_zone_name" \
    -f $SCRIPT_DIR/../helm-values/k8gb/values.yaml

  # Setup default page deployment
  kubectl apply -f - <<END
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: default-page
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: maintenance
      port:
        number: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: maintenance
  name: maintenance
spec:
  replicas: 1
  selector:
    matchLabels:
      app: maintenance
  template:
    metadata:
      labels:
        app: maintenance
    spec:
      containers:
        - image: wickerlabs/maintenance
          name: maintenance
          ports:
            - containerPort: 8080
          resources: {}
          env:
            - name: MESSAGE
              value: "This is the default page for the demo setup."
            - name: TITLE
              value: "$CLUSTER_NAME - k8gb demo setup"
            - name: HEADLINE
              value: "$CURRENT_CLUSTER_LOCATION"
            - name: TEAM_NAME
              value: ""
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: maintenance
  name: maintenance
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
  selector:
    app: maintenance
  type: ClusterIP
END

  echo "k8gb demo setup complete on cluster $CLUSTER_NAME."
done