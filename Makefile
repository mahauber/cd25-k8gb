GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RED := \033[0;31m
RESET := \033[0m

SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash
DEMO_DIR := /mnt/f/Prodyna/Talks/cd25-k8gb

# Phony targets (targets that don't represent files)
.PHONY: demo1 demo2 help clean

# Help target to display available commands
help:
	@echo -e "${BLUE}Available Targets:${RESET}"
	@echo -e "  ${GREEN}demo1${RESET}   - Kubernetes service scaling demonstration"
	@echo -e "  ${GREEN}demo2${RESET}   - Additional Kubernetes demo (customize as needed)"
	@echo -e "  ${GREEN}help${RESET}    - Show this help message"

k9s:
	@echo -e "${BLUE}Starting k9s in Windows Terminal...${RESET}"
	@cmd.exe /c start wt -w 0 nt --tabColor "#48c8ffff" --title "Swedencentral" wsl -e k9s --context "aks-sdc" -c "pods" --logoless -A
	@cmd.exe /c start wt -w 0 nt --tabColor "#0003c0ff" --title "Germanywestcentral" wsl -e k9s --context "aks-gwc" -c "pods" --logoless -A

# Demo 1: Kubernetes Service Scaling
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

# Demo 2 (example - customize as needed)
demo2:
	@echo -e "${YELLOW}➡️   Demo 2: Additional Kubernetes Demonstration${RESET}"
	@# Add your specific commands here
	@echo -e "${GREEN}✅ Demo 2 completed${RESET}"

# Clean up target (example)
clean:
	@echo -e "${BLUE}Cleaning up...${RESET}"
	@# Add any cleanup commands here

# Default target
default: help