#!/bin/bash

set -euo pipefail

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
  echo "Azure CLI (az) not found. Please install it before running this script."
  exit 1
fi

# Set variables
CLUSTERS=("aks-gwc" "aks-sdc")
SUBSCRIPTION_ID="88155474-d55e-4910-9a6f-9ea5ccc6d281"
TENANT_ID="$(az account show --query tenantId -o tsv)"
DNS_ZONE_RESOURCE_GROUP="rg-dns"
DNS_ZONE_NAME="cd25.k8st.cc"
LOAD_BALANCED_ZONE="demo.cd25.k8st.cc"

# Add and update Helm repositories (only once)
helm repo add k8gb https://www.k8gb.io
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

for CLUSTER_NAME in "${CLUSTERS[@]}"; do
  echo "#################################"
  echo "## Setting up cluster: $CLUSTER_NAME ##"
  echo "#################################"

  # Get credentials for the AKS cluster
  az aks get-credentials --resource-group rg-$CLUSTER_NAME --name $CLUSTER_NAME --subscription $SUBSCRIPTION_ID --overwrite-existing
  
  CURRENT_CLUSTER_LOCATION=$(az aks show --resource-group rg-$CLUSTER_NAME --name $CLUSTER_NAME --query location -o tsv)

  CLEAN_ALL_CLUSTER_LOCATIONS=$(comm -23 <(az aks list --query "[].location" -o tsv | sort) <(echo $CURRENT_CLUSTER_LOCATION | sort))
  CLEAN_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS=$(echo $CLEAN_ALL_CLUSTER_LOCATIONS | paste -sd,)
  CLEAN_ESCAPED_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS="${CLEAN_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS//,/\\,}" # escape commas for Helm values

  # Install NGINX Ingress Controller
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --version 4.13.0 \
    --create-namespace \
    --namespace ingress-nginx \
    -f ./helm-values/ingress-nginx/values.yaml

  # SETUP K8GB

  # create secret for reference to managed identity https://github.com/k8gb-io/external-dns/blob/master/docs/tutorials/azure.md
kubectl apply -f - <<END
apiVersion: v1
kind: Secret
metadata:
  name: external-dns-secret-azure
type: Opaque
data:
  azure.json: $(cat <<EOF | base64 | tr -d '\n'
{
  "tenantId": "$TENANT_ID",
  "subscriptionId": "$SUBSCRIPTION_ID",
  "resourceGroup": "$DNS_ZONE_RESOURCE_GROUP",
  "useManagedIdentityExtension": true
}
EOF
)
END
  
  env

helm upgrade --install k8gb k8gb/k8gb \
  --namespace k8gb \
  --create-namespace \
  --version 0.15.0-rc3 \
  --set "k8gb.clusterGeoTag=$CURRENT_CLUSTER_LOCATION" \
  --set "k8gb.extGslbClustersGeoTags=$CLEAN_ESCAPED_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS" \
  --set "k8gb.dnsZones[0].loadBalancedZone=$DNS_ZONE_NAME" \
  --set "k8gb.dnsZones[0].parentZone=$LOAD_BALANCED_ZONE" \
  -f ./helm-values/k8gb/values.yaml

  # Install podinfo
  helm upgrade --install podinfo podinfo/podinfo \
    --namespace default \
    --version 6.9.1 \
    --set ui.message="$CLUSTER_NAME" \
    --set ui.color="#fab41e" \
    --set ui.logo="https://dummyimage.com/600x400/fab41e/3C4146&text=$CURRENT_CLUSTER_LOCATION"

  echo "k8gb demo setup complete on cluster $CLUSTER_NAME."
done