#!/bin/bash

set -euo pipefail

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

# Set variables
CLUSTERS=("aks-gwc" "aks-sdc")
SUBSCRIPTION_ID="88155474-d55e-4910-9a6f-9ea5ccc6d281"
TENANT_ID="$(az account show --query tenantId -o tsv)"
DNS_ZONE_RESOURCE_GROUP="dns-zone"
DNS_ZONE_NAME="cd25.k8st.cc"
LOAD_BALANCED_ZONE="demo.cd25.k8st.cc"
PRIMARY_GEO_TAG="germanywestcentral"

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
  az aks get-credentials --resource-group $CLUSTER_NAME --name $CLUSTER_NAME --subscription $SUBSCRIPTION_ID --overwrite-existing
  kubelogin convert-kubeconfig -l azurecli

  CURRENT_CLUSTER_LOCATION=$(az aks show --resource-group $CLUSTER_NAME --name $CLUSTER_NAME --query location -o tsv)

  CLEAN_ALL_CLUSTER_LOCATIONS=$(comm -23 <(az aks list --query "[].location" -o tsv | sort) <(echo $CURRENT_CLUSTER_LOCATION | sort))
  CLEAN_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS=$(echo $CLEAN_ALL_CLUSTER_LOCATIONS | paste -sd,)
  CLEAN_ESCAPED_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS="${CLEAN_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS//,/\\,}" # escape commas for Helm values

  # Install NGINX Ingress Controller
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --version 4.13.0 \
    --create-namespace \
    --namespace ingress-nginx \
    -f ./helm-values/ingress-nginx/values.yaml

    kubectl apply -f - <<END
apiVersion: v1
kind: Namespace
metadata:
  labels:
    kubernetes.io/metadata.name: k8gb
  name: k8gb
spec:
END

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
  "subscriptionId": "$SUBSCRIPTION_ID",
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
    --set ui.logo="https://dummyimage.com/600x400/fab41e/3C4146&text=$CURRENT_CLUSTER_LOCATION" \
    -f ./helm-values/podinfo/values.yaml

  helm upgrade --install k8gb k8gb/k8gb \
    --namespace k8gb \
    --create-namespace \
    --version 0.14.0 \
    --set "k8gb.clusterGeoTag=$CURRENT_CLUSTER_LOCATION" \
    --set "k8gb.extGslbClustersGeoTags=$CLEAN_ESCAPED_COMMA_SEPARATED_ALL_CLUSTER_LOCATIONS" \
    --set "k8gb.dnsZone=$LOAD_BALANCED_ZONE" \
    --set "k8gb.edgeDNSZone=$DNS_ZONE_NAME" \
    -f ./helm-values/k8gb/values.yaml

    kubectl apply -f - <<END
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: defaul-page
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