SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash

export DNS_ZONE_RESOURCE_GROUP := dns-zone
export TF_VAR_dns_zone_name := cd25.k8st.cc
export LOAD_BALANCED_ZONE := demo.cd25.k8st.cc

export PRIMARY_GEO_TAG := germanywestcentral
export TF_VAR_subscription_id := 88155474-d55e-4910-9a6f-9ea5ccc6d281
export TENANT_ID := 60fb1cfc-a9ef-4a93-b5e8-5d021bd6f296 # az account show --query tenantId -o tsv
export CLUSTERS := aks-gwc aks-acl

# export CLOUDFLARE_API_KEY := your_api_key
export CLOUDFLARE_ZONE_ID := bb6f8fe1622eef68d50a90eede65dffc

.PHONY: init-demo-aks init-demo-aks-tf init-demo-aks-helm destroy-demo-aks

# --------------------
# Apply targets
# --------------------
init-demo-aks: az-login init-demo-aks-tf init-demo-aks-helm init-demo-aks-cloudflare
	@echo "✅   Finished SETUP"

az-login:
	@echo "➡️   Logging into Azure"
	@az login --tenant $(TENANT_ID)

init-demo-aks-tf:
	@echo "➡️   Setting up Azure AKS & DNS"
	cd $(SCRIPT_DIR)modules/aks-demo && tofu init -upgrade && tofu apply -auto-approve

init-demo-aks-helm:
	@echo "➡️   Setting up Helm for AKS"
	$(SCRIPT_DIR)scripts/set-up-helm-charts.sh
	@echo "✅   Finished Helm setup. Access the application at: http://podinfo.demo.cd25.k8st.cc and http://podinfo.k8st.cc"

init-demo-aks-cloudflare:
	@echo "➡️   Setting up Cloudflare DNS"
	$(SCRIPT_DIR)scripts/set-up-cloudflare.sh

destroy-demo-aks:
	@echo "➡️   Destroying Azure AKS & DNS"
	cd $(SCRIPT_DIR)modules/aks-demo && tofu destroy -auto-approve