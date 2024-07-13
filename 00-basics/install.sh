#!/bin/bash

# Get the absolute path of the script
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source the environment variables from settings.sh in the parent directory
source "${SCRIPT_DIR}/../settings.sh"

# Install or upgrade CertManager
echo ""
echo "${bold}Installing or upgrading CertManager...${normal}"
echo ""
helm upgrade --install cert-manager cert-manager \
  --repo https://charts.jetstack.io \
  --namespace cert-manager \
  --create-namespace \
  --version ${CERT_MANAGER_VERSION} \
  --values cert-manager-values.yaml \
  --wait

# Check if CertManager was successfully deployed
if [ $? -eq 0 ]; then
  echo ""
  echo "${bold}CertManager installed successfully.${normal}"
  echo ""
else
  echo ""
  echo "${bold}Failed to install CertManager.${normal}"
  echo ""
  exit 1
fi