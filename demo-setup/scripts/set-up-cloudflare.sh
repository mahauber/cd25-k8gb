#!/bin/bash

# Get nameservers from Azure DNS zone
nameservers=$(az network dns zone show -n cd25.k8st.cc -g dns-zone -o tsv --query nameServers)

# Setup nameservers in Cloudflare
for ns in $nameservers; do
    echo "Adding nameserver: $ns"
    curl -s https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
        -d "{
              \"name\": \"cd25\",
              \"ttl\": 3600,
              \"type\": \"NS\",
              \"content\": \"$ns\",
              \"proxied\": false
            }"  | jq '.'
    echo ""
done

# Get IP addresses from ingress-nginx services
kubectx aks-gwc
GWC_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
kubectx aks-sdc
SDC_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Check if IPs were retrieved successfully
if [ -z "$GWC_IP" ]; then
    echo "Error: Could not retrieve IP for GWC ingress controller"
    exit 1
fi

if [ -z "$SDC_IP" ]; then
    echo "Error: Could not retrieve IP for SDC ingress controller"
    exit 1
fi

echo "GWC IP: $GWC_IP"
echo "SDC IP: $SDC_IP"

# Setup AKS A records
echo "Creating A record for aks-gwc.traf..."
curl -s https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
    -d "{
          \"name\": \"aks-gwc.traf\",
          \"ttl\": 3600,
          \"type\": \"A\",
          \"content\": \"$GWC_IP\",
          \"proxied\": false
        }" | jq '.'

echo ""
echo "Creating A record for aks-sdc.traf..."
curl -s https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
    -d "{
          \"name\": \"aks-sdc.traf\",
          \"ttl\": 3600,
          \"type\": \"A\",
          \"content\": \"$SDC_IP\",
          \"proxied\": false
        }" | jq '.'

echo "Creating A record for traf-podinfo-demo-cd25.trafficmanager.net..."
curl -s https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
    -d "{
          \"name\": \"podinfo\",
          \"ttl\": 3600,
          \"type\": \"CNAME\",
          \"content\": \"traf-podinfo-demo-cd25.trafficmanager.net\",
          \"proxied\": false
        }" | jq '.'
