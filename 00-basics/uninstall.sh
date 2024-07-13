#!/bin/bash

# Get the absolute path of the script
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source the environment variables from settings.sh in the parent directory
source "${SCRIPT_DIR}/../settings.sh"

# Uninstall cert-manager Helm release
echo "Uninstalling cert-manager Helm release..."
helm uninstall cert-manager --namespace cert-manager || echo "cert-manager Helm release not found, skipping uninstall."

# Check if the Helm release was successfully deleted
if [ $? -eq 0 ]; then
  echo "cert-manager Helm release deleted successfully."
else
  echo "Failed to delete cert-manager Helm release."
  exit 1
fi

# Delete CRDs and their objects
delete_crd_and_objects "certificates.cert-manager.io"
delete_crd_and_objects "certificaterequests.cert-manager.io"
delete_crd_and_objects "challenges.acme.cert-manager.io"
delete_crd_and_objects "clusterissuers.cert-manager.io"
delete_crd_and_objects "issuers.cert-manager.io"
delete_crd_and_objects "orders.acme.cert-manager.io"

# Delete the namespace
echo "Deleting the cert-manager namespace..."
kubectl delete namespace cert-manager --ignore-not-found

# Check if the namespace was successfully deleted
if [ $? -eq 0 ]; then
  echo "cert-manager namespace deleted successfully."
else
  echo "Failed to delete cert-manager namespace."
  exit 1
fi

echo "cert-manager removal completed."