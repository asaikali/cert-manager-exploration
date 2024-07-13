#!/bin/bash

# Get the absolute path of the script
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Source the environment variables from settings.sh in the parent directory
source "${SCRIPT_DIR}/settings.sh"


delete_crd_and_objects() {
  local crd=$1
  local objects_deleted=false
  local crd_deleted=false

  echo ""
  # Delete all objects for the CRD
  if kubectl delete $crd --all --ignore-not-found &>/dev/null; then
    objects_deleted=true
  fi

  # Delete the CRD itself
  if kubectl delete crd $crd --ignore-not-found &>/dev/null; then
    crd_deleted=true
  fi

  # Print a summary
  if $objects_deleted || $crd_deleted; then
    echo "Deleted CRD: $crd"
    [ "$objects_deleted" = true ] && echo "  - Associated objects removed"
    [ "$crd_deleted" = true ] && echo "  - CRD definition removed"
  else
    echo "No changes for CRD: $crd"
  fi

  echo ""
}
verify_and_cleanup_crds() {
    local release_name="$1"
    shift
    local expected_crds=("$@")
    
    echo "${bold}Verifying and cleaning up CRDs for $release_name...${normal}"
    
    # Get installed CRDs for the release
    local installed_crds=($(kubectl get crd -l app.kubernetes.io/name=$release_name -o custom-columns=NAME:.metadata.name --no-headers 2>/dev/null))

    # If no CRDs are found, don't treat it as an error
    if [ ${#installed_crds[@]} -eq 0 ]; then
        echo "No CRDs found for $release_name. Skipping CRD cleanup."
        return 0
    fi

    # Check for unexpected CRDs
    local unexpected_crds=()
    for crd in "${installed_crds[@]}"; do
        if ! [[ " ${expected_crds[*]} " =~ " ${crd} " ]]; then
            unexpected_crds+=("$crd")
        fi
    done

    if [ ${#unexpected_crds[@]} -gt 0 ]; then
        echo "${bold}Warning: Unexpected CRDs found for $release_name:${normal}"
        printf '%s\n' "${unexpected_crds[@]}"
    fi

    # Cleanup CRDs
    for crd in "${expected_crds[@]}"; do
        if [[ " ${installed_crds[*]} " =~ " ${crd} " ]]; then
            echo "Deleting CRD $crd and its objects..."
            delete_crd_and_objects "$crd"
        else
            echo "CRD $crd not found. Skipping."
        fi
    done

    echo "${bold}CRD verification and cleanup for $release_name completed.${normal}"
    echo ""
}

uninstall_helm_release() {
    local release_name="$1"
    local namespace="$2"
    shift 2
    local expected_crds=("$@")

    # Check if both release name and namespace are provided
    if [ -z "$release_name" ] || [ -z "$namespace" ]; then
        echo "${bold}Error: Both release name and namespace must be provided.${normal}"
        echo "Usage: uninstall_helm_release <release_name> <namespace> [<crd1> <crd2> ...]"
        return 1
    fi

    echo ""
    echo "${bold}Uninstalling Helm release: $release_name from namespace: $namespace${normal}"
    echo ""

    # Check if the release exists
    if helm status "$release_name" -n "$namespace" &>/dev/null; then
        helm uninstall "$release_name" -n "$namespace"
        
        # Check if uninstallation was successful
        if [ $? -ne 0 ]; then
            echo "${bold}Failed to uninstall $release_name Helm release.${normal}"
            return 1
        fi
        echo "${bold}$release_name Helm release uninstalled successfully.${normal}"
    else
        echo "${bold}$release_name Helm release not found in namespace $namespace. Skipping Helm uninstallation.${normal}"
    fi

    # CRD verification and cleanup
    if [ ${#expected_crds[@]} -gt 0 ]; then
        verify_and_cleanup_crds "$release_name" "${expected_crds[@]}"
    else
        echo "${bold}No CRDs specified for cleanup.${normal}"
    fi

    echo "${bold}Uninstallation of $release_name completed.${normal}"
    echo ""
}
uninstall_cert_manager() {
  local cert_manager_crds=(
    # Certificates should be deleted first as they depend on other resources
    "certificates.cert-manager.io"

    # CertificateRequests are created by Certificates, so they should be next
    "certificaterequests.cert-manager.io"

    # Orders are created as part of the ACME process for Certificates
    "orders.acme.cert-manager.io"

    # Challenges are created by Orders in the ACME process
    "challenges.acme.cert-manager.io"

    # Issuers should be deleted after the resources that use them
    "issuers.cert-manager.io"

    # ClusterIssuers are cluster-wide resources and should be deleted last
    "clusterissuers.cert-manager.io"
  )

  echo "${bold}Uninstalling cert-manager with CRDs in the following order:${normal}"
  for crd in "${cert_manager_crds[@]}"; do
    echo " - $crd"
  done
  echo ""

  uninstall_helm_release "cert-manager" "cert-manager" "${cert_manager_crds[@]}"
}
uninstall_cert_manager