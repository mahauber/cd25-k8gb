SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash

DNS_ZONE_RESOURCE_GROUP := "dns-zone"
DNS_ZONE_NAME := "cd25.k8st.cc"
LOAD_BALANCED_ZONE := "demo.cd25.k8st.cc"
PRIMARY_GEO_TAG := "germanywestcentral"
CLUSTERS := ("aks-gwc" "aks-sdc")
SUBSCRIPTION_ID := "88155474-d55e-4910-9a6f-9ea5ccc6d281"
TENANT_ID := "your-tenant-id"


.PHONY: init-demo-aks init-demo-aks-tf init-demo-aks-helm destroy-demo-aks

# --------------------
# Apply targets
# --------------------
init-demo-aks: az-login init-demo-aks-tf init-demo-aks-helm
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
	@echo "✅   Finished Helm setup. Access the application at: http://podinfo.demo.cd25.k8st.cc"

destroy-demo-aks:
	@echo "➡️   Destroying Azure AKS & DNS"
	cd $(SCRIPT_DIR)modules/aks-demo && tofu destroy -auto-approve