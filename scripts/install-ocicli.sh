#!/bin/bash
set -eo pipefail

# Create isolated virtual environment
python3 -m venv /opt/ocicli
source /opt/ocicli/bin/activate

pip install --upgrade pip
# Install OCI CLI within virtual environment
pip install --no-cache-dir oci-cli

# Create symlink for system-wide access
ln -sf /opt/ocicli/bin/oci /usr/local/bin/oci

# Verify installation
oci --version || { echo "OCI CLI installation failed"; exit 1; }
