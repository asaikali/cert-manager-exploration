# Define the bold text format
bold=$(tput bold)
normal=$(tput sgr0)

# Define version numbers
CERT_MANAGER_VERSION="v1.15.1"
CERT_MANAGER_APPROVER_POLICY_VERSION="0.14.1"
CERT_MANAGER_CSI_DRIVER_VERSION="v0.9.0"
CERT_MANAGER_CSI_DRIVER_SPIFEE_VERSION="0.7.0"
TRUST_MANAGER_VERSION="0.11.0"

delete_crd_and_objects() {
  local crd=$1
  echo ""
  echo "${bold}Deleting all objects for CRD $crd...${normal}"
  kubectl delete $crd --all --ignore-not-found

  echo "${bold}Deleting CRD $crd...${normal}"
  kubectl delete crd $crd --ignore-not-found
  echo ""
}