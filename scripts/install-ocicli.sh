#!/bin/bash
set -eo pipefail

if ! pip --version &> /dev/null
then
    echo "pip could not be found, installing pip..."
    sudo apt update
    sudo apt install -y python3-pip
fi

pip install --upgrade pip
# Create isolated virtual environment
python3 -m venv oracle_cli
source oracle_cli/bin/activate

# Install OCI CLI within virtual environment
pip install oci-cli 

# Create symlink for system-wide access
sudo ln -s /oracle_cli/bin/oci /usr/local/bin/oci


# Verify installation
oci --version || { echo "OCI CLI installation failed"; exit 1; }
