#!/bin/bash

# Check if OpenTofu is installed
if ! command -v tofu &> /dev/null; then
  echo "OpenTofu is not installed. Please install it before running this script."
  exit 1
fi

# todo: Set variables instead of auto tfvars

tofu apply 
