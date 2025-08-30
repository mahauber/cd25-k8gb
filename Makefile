GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RED := \033[0;31m
RESET := \033[0m

SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash
DEMO_DIR := /mnt/f/Prodyna/Talks/cd25-k8gb

PRIMARY_AKS_NAME := aks-gwc
SECONDARY_AKS_NAME := aks-acl
SUBSCRIPTION_ID := 88155474-d55e-4910-9a6f-9ea5ccc6d281

# Phony targets (targets that don't represent files)
.PHONY: demo1 demo2 help clean

# Help target to display available commands
help:
	@echo -e "${BLUE}Available Targets:${RESET}"
	@echo -e "  ${GREEN}initial-setup${RESET} - Set up the demo environment"
	@echo -e "  ${GREEN}start${RESET}   - Start both AKS clusters"
	@echo -e "  ${GREEN}k9s${RESET}     - Start k9s in Windows Terminal"
	@echo -e "  ${GREEN}demo1${RESET}   - Kubernetes service scaling demonstration"
	@echo -e "  ${GREEN}demo2${RESET}   - Additional Kubernetes demo (customize as needed)"
	@echo -e "  ${GREEN}stop${RESET}    - Stop both AKS clusters"
	@echo -e "  ${GREEN}destroy-demo${RESET} - Destroy the demo environment"
	@echo -e "  ${GREEN}help${RESET}    - Show this help message"

initial-setup:
	@echo -e "${BLUE}Running initial setup...${RESET}"
	@make -C ${SCRIPT_DIR}demo-setup init-demo-aks

start:
	@echo -e "${BLUE}Starting clusters...${RESET}"
	@az aks start --name ${PRIMARY_AKS_NAME} --resource-group ${PRIMARY_AKS_NAME} --subscription ${SUBSCRIPTION_ID} | true
	@az aks start --name ${SECONDARY_AKS_NAME} --resource-group ${SECONDARY_AKS_NAME} --subscription ${SUBSCRIPTION_ID} | true

k9s:
	@echo -e "${BLUE}Starting k9s in Windows Terminal...${RESET}"
	@cmd.exe /c start wt -w 0 nt --tabColor "#48c8ffff" --title "Australiacentral" wsl -e k9s --context "aks-acl" -c "pods" --logoless -A
	@cmd.exe /c start wt -w 0 nt --tabColor "#0003c0ff" --title "Germanywestcentral" wsl -e k9s --context "aks-gwc" -c "pods" --logoless -A

# Demo 1: Kubernetes Service Scaling ==> failover fast due to communication between k8gb cluster instances
demo1:
	@echo -e "${YELLOW}➡️   Demo 1: Kubernetes SVC without endpoints${RESET}"
	@cmd.exe /c start wsl.exe -- watch -t -n 1 -w -d 'echo "${GREEN}Current IP-address:${RESET}" && dig +short podinfo.demo.cd25.k8st.cc && echo "${YELLOW}Current cluster:${RESET}" && (curl -s http://podinfo.demo.cd25.k8st.cc | jq -r ".message" 2>/dev/null || echo "${RED}cluster down${RESET}")'
	@echo -e "${BLUE}Switching context to AKS...${RESET}"
	@kubectx aks-gwc
	
	@echo -e "${YELLOW}Scaling down podinfo deployment to 0 replicas${RESET}"
	@sleep 5
	@kubectl scale deployment podinfo --replicas=0
	
	@read -p "$(shell echo -e "${GREEN}Press enter to continue scaling up...${RESET}")"
	
	@echo -e "${YELLOW}Scaling up podinfo deployment to 1 replica${RESET}"
	@kubectl scale deployment podinfo --replicas=1
	
	@echo -e "${GREEN}✅ Demo 1 completed successfully${RESET}"

# Demo 2: Traffic manager weighted
demo2:
	@echo -e "${YELLOW}➡️   Demo 2: Traffic manager weighted${RESET}"
	@cmd.exe /c start wsl.exe -- watch -t -n 1 -w -d 'echo "${GREEN}Current IP-address:${RESET}" && dig +short podinfo.k8st.cc && echo "${YELLOW}DNS chain:${RESET}" && (curl -s http://podinfo.k8st.cc | jq -r ".message" 2>/dev/null || echo "${RED}cluster down${RESET}")'
	@echo -e "${BLUE}Switching context to AKS...${RESET}"
	@kubectx aks-gwc
	
	@echo -e "${YELLOW}Scaling down podinfo deployment to 0 replicas${RESET}"
	@sleep 5
	@kubectl scale deployment podinfo --replicas=0
	
	@read -p "$(shell echo -e "${GREEN}Press enter to continue scaling up...${RESET}")"
	
	@echo -e "${YELLOW}Scaling up podinfo deployment to 1 replica${RESET}"
	@kubectl scale deployment podinfo --replicas=1
	
	@echo -e "${GREEN}✅ Demo 1 completed successfully${RESET}"

# Demo 3: Primary AKS shutdown ==> takes way longer (~2min) to failover
demo3:
	@echo -e "${YELLOW}➡️   Demo 3: Primary AKS shutdown${RESET}"
	@echo -e "${BLUE}Shutting down primary AKS...${RESET}"
	@cmd.exe /c start wsl.exe -- watch -t -n 1 -w -d 'echo "${GREEN}Current IP-address:${RESET}" && dig +short podinfo.demo.cd25.k8st.cc && echo "${YELLOW}Current cluster:${RESET}" && (curl -s http://podinfo.demo.cd25.k8st.cc | jq -r ".message" 2>/dev/null || echo "${RED}cluster down${RESET}")'
	@az aks stop --name ${PRIMARY_AKS_NAME} --resource-group ${PRIMARY_AKS_NAME} --subscription ${SUBSCRIPTION_ID}

	@echo -e "${YELLOW}Starting primary AKS again...${RESET}"
	@az aks start --name ${PRIMARY_AKS_NAME} --resource-group ${PRIMARY_AKS_NAME} --subscription ${SUBSCRIPTION_ID}

	@echo -e "${GREEN}✅ Demo 3 completed successfully${RESET}"

stop:
	@echo -e "${BLUE}Stopping clusters...${RESET}"
	@az aks stop --name ${PRIMARY_AKS_NAME} --resource-group ${PRIMARY_AKS_NAME} --subscription ${SUBSCRIPTION_ID}
	@az aks stop --name ${SECONDARY_AKS_NAME} --resource-group ${SECONDARY_AKS_NAME} --subscription ${SUBSCRIPTION_ID}

destroy-demo:
	@echo -e "${BLUE}Destroying demo environment...${RESET}"
	@make -C ${SCRIPT_DIR}demo-setup destroy-demo-aks

# Default target
default: help