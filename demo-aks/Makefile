SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash

.PHONY: init-demo-aks init-demo-aks-tf init-demo-aks-helm destroy-demo-aks

# --------------------
# Apply targets
# --------------------
init-demo-aks: init-demo-aks-tf init-demo-aks-helm
	@echo "✅   Finished SETUP"

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