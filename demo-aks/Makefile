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
	cd $(SCRIPT_DIR)modules/aks-dns && tofu apply -auto-approve

init-demo-aks-helm:
	@echo "➡️   Setting up Helm for AKS"
	$(SCRIPT_DIR)set-up-helm.sh

destroy-demo-aks:
	@echo "➡️   Destroying Azure AKS & DNS"
	cd $(SCRIPT_DIR)modules/aks-dns && tofu destroy -auto-approve