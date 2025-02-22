#!/bin/bash
set -eo pipefail

# Configuration paths
OCI_CONFIG_DIR="/home/backenduser/.kube/"
MANUAL_CONFIG_DIR="/home/backenduser/.kube/manual"
OCI_CONFIG="${OCI_CONFIG_DIR}/config"
MANUAL_CONFIG="${MANUAL_CONFIG_DIR}/config"

# Ensure directories exist
mkdir -p "${OCI_CONFIG_DIR}" "${MANUAL_CONFIG_DIR}"

if [ "$KUBECONFIG_MODE" = "oci" ]; then
  echo "Initializing OCI OKE configuration..."
  
  # Validate required OCI variables
  required_vars=(OCI_TENANCY_OCID OCI_USER_OCID OCI_REGION OCI_FINGERPRINT OCI_KEY_FILE OKE_CLUSTER_NAME)
  for var in "${required_vars[@]}"; do
      if [[ -z "${!var}" ]]; then
          echo "ERROR: Missing required environment variable $var" >&2
          exit 1
      fi
  done
  
  # Clean existing OCI config
  rm -f "${OCI_CONFIG}"
  
  # Configure OCI CLI
  oci configure set oci_tenancy ${OCI_TENANCY_OCID}
  oci configure set oci_user ${OCI_USER_OCID}
  oci configure set default.region ${OCI_REGION}
  oci configure set fingerprint ${OCI_FINGERPRINT}
  oci configure set key_file ${OCI_KEY_FILE}

  # Verify OKE cluster exists
  if ! oci ce cluster get --cluster-id $(oci ce cluster list --name ${OKE_CLUSTER_NAME} --query 'data[0].id' --raw-output) >/dev/null; then
      echo "ERROR: Failed to access OKE cluster '${OKE_CLUSTER_NAME}'" >&2
      exit 1
  fi
  
  # Generate fresh config
  # Backup existing kubeconfig if it exists
  if [ -f "${OCI_CONFIG}" ]; then
    cp "${OCI_CONFIG}" "${OCI_CONFIG}.bak"
    echo "Existing kubeconfig backed up to ${OCI_CONFIG}.bak"
  fi

  # Generate fresh kubeconfig
  oci ce cluster create-kubeconfig \
    --cluster-id $(oci ce cluster list --name ${OKE_CLUSTER_NAME} --query 'data[0].id' --raw-output) \
    --file "${OCI_CONFIG}" \
    --region "${OCI_REGION}" \
    --token-version 2.0.0
    
  export KUBECONFIG="${OCI_CONFIG}"

elif [ "$KUBECONFIG_MODE" = "manual" ]; then
  echo "Using manual kubeconfig..."
  
  if [ ! -f "${MANUAL_CONFIG}" ]; then
    echo "ERROR: Manual config not found at ${MANUAL_CONFIG}"
    exit 1
  fi
  
  export KUBECONFIG="${MANUAL_CONFIG}"

else
  echo "ERROR: Invalid KUBECONFIG_MODE '${KUBECONFIG_MODE}'"
  exit 1
fi

# Verify cluster access
if ! kubectl cluster-info --request-timeout=10s; then
  echo "Failed to connect to Kubernetes cluster"
  exit 1
fi

# Verify kubectl version
echo "Kubectl Version:"
kubectl version --client -o json | jq -r '.clientVersion.gitVersion'

exec "$@"
