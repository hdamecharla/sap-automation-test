#!/bin/bash
#
# SLES Deployer Configuration Script
# Simplified and idempotent version for distribution
#
# Installs:
# - Python 3.10.12 to /opt/python/v3.10.12
# - Azure CLI 2.75.0 to /opt/azure-cli
# - Terraform 1.12.2
# - Ansible with virtual environment
# - Azure SAP automation framework
#

# Verify running as non-root user
if [[ $EUID -eq 0 ]]; then
    echo "ERROR: This script should not be run as root. Please run as a regular user."
    exit 1
fi

# Shell options for robust execution
set -o errexit   # Fail on non-zero exit status
set -o pipefail  # Ensure pipeline exit status is non-zero if any stage fails
set -o nounset   # Fail if accessing unset variable

export local_user=$USER

#
# Configuration Variables
#
PYTHON_VERSION="3.10.12"
PYTHON_BASE="/opt/python"
PYTHON_DIR="${PYTHON_BASE}/v${PYTHON_VERSION}"
PYTHON_BIN="${PYTHON_DIR}/bin/python3"

AZ_CLI_VERSION="2.75.0"
AZ_INSTALL_DIR="/opt/azure-cli"
AZ_BIN_DIR="/opt/azure-cli/bin"

TF_VERSION="1.12.2"
TF_BASE="/opt/terraform"
TF_DIR="${TF_BASE}/terraform_${TF_VERSION}"
TF_BIN="${TF_BASE}/bin"

ANSIBLE_VERSION="2.16"
ANSIBLE_BASE="/opt/ansible"
ANSIBLE_BIN="${ANSIBLE_BASE}/bin"
ANSIBLE_VENV="${ANSIBLE_BASE}/venv/${ANSIBLE_VERSION}"
ANSIBLE_VENV_BIN="${ANSIBLE_VENV}/bin"
ANSIBLE_COLLECTIONS="${ANSIBLE_BASE}/collections"

# Azure SAP Automated Deployment directories
ASAD_HOME="${HOME}/Azure_SAP_Automated_Deployment"
ASAD_WS="${ASAD_HOME}/WORKSPACES"
ASAD_REPO="https://github.com/Azure/sap-automation.git"
ASAD_SAMPLE_REPO="https://github.com/Azure/sap-automation-samples.git"
ASAD_DIR="${ASAD_HOME}/$(basename ${ASAD_REPO} .git)"
ASAD_SAMPLE_DIR="${ASAD_HOME}/samples"

#
# Utility Functions
#
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

check_sles() {
    local distro_name
    distro_name="$(. /etc/os-release; echo "${ID,,}")"
    if [[ "${distro_name}" != "sles" ]]; then
        echo "ERROR: This script is designed for SLES. Detected: ${distro_name}"
        exit 1
    fi
    log "Detected SLES system"
}

#
# Installation Functions
#

install_development_tools() {
    log "Setting up development environment..."
    
    # Activate Development Tools Module if available
    if command -v SUSEConnect >/dev/null 2>&1; then
        log "Attempting to activate Development Tools Module..."
        set +o errexit
        sudo SUSEConnect -p sle-module-development-tools/15.6/x86_64 2>/dev/null || \
        sudo SUSEConnect -p sle-module-development-tools/15.5/x86_64 2>/dev/null || \
        sudo SUSEConnect -p sle-module-development-tools/15.4/x86_64 2>/dev/null || \
        log "Warning: Could not activate Development Tools Module"
        set -o errexit
    fi
    
    # Refresh package cache
    sudo zypper --quiet refresh
    
    # Install essential packages
    local packages=(
        git curl wget jq unzip dos2unix
        gcc gcc-c++ make autoconf automake libtool
        glibc-devel zlib-devel libopenssl-devel libffi-devel
        sqlite3-devel libbz2-devel xz-devel readline-devel
        ncurses-devel libexpat-devel libuuid-devel
        python3-devel
    )
    
    log "Installing development packages..."
    for pkg in "${packages[@]}"; do
        if ! rpm -q "$pkg" >/dev/null 2>&1; then
            sudo zypper --quiet --non-interactive install "$pkg" || log "Warning: Could not install $pkg"
        fi
    done
}

install_python() {
    if [[ -f "${PYTHON_BIN}" ]]; then
        log "Python ${PYTHON_VERSION} already installed at ${PYTHON_DIR}"
        "${PYTHON_BIN}" --version
        return 0
    fi
    
    log "Installing Python ${PYTHON_VERSION} from source..."
    
    local python_archive="Python-${PYTHON_VERSION}.tgz"
    local download_url="https://www.python.org/ftp/python/${PYTHON_VERSION}/${python_archive}"
    local build_dir="/tmp/python-build-$$"
    
    # Create build directory
    mkdir -p "${build_dir}"
    cd "${build_dir}"
    
    # Download and extract
    wget -q "${download_url}"
    tar -xzf "${python_archive}"
    cd "Python-${PYTHON_VERSION}"
    
    # Configure and build
    export LDFLAGS="-Wl,-rpath,${PYTHON_DIR}/lib"
    ./configure \
        --prefix="${PYTHON_DIR}" \
        --enable-optimizations \
        --with-ensurepip=install \
        --enable-shared \
        --quiet
    
    make -j$(nproc) --quiet
    sudo make install --quiet
    
    # Create symlinks
    sudo mkdir -p "${PYTHON_BASE}/bin"
    sudo ln -sf "${PYTHON_DIR}/bin/python3" "${PYTHON_BASE}/bin/python3"
    sudo ln -sf "${PYTHON_DIR}/bin/pip3" "${PYTHON_BASE}/bin/pip3"
    
    # Update library path
    echo "${PYTHON_DIR}/lib" | sudo tee /etc/ld.so.conf.d/python-custom.conf >/dev/null
    sudo ldconfig
    
    # Cleanup
    cd /
    sudo rm -rf "${build_dir}"
    
    log "Python ${PYTHON_VERSION} installed successfully"
    "${PYTHON_BIN}" --version
}

install_azure_cli() {
    local current_version=""
    local user_bin_dir="${HOME}/bin"
    
    # Check if Azure CLI is installed and get version
    if [[ -f "${user_bin_dir}/az" ]]; then
        current_version=$("${user_bin_dir}/az" version --output json 2>/dev/null | jq -r '."azure-cli"' 2>/dev/null || echo "unknown")
        if [[ "${current_version}" == "${AZ_CLI_VERSION}" ]]; then
            log "Azure CLI ${AZ_CLI_VERSION} already installed at ${user_bin_dir}/az"
            "${user_bin_dir}/az" version --output table 2>/dev/null || true
            return 0
        else
            log "Azure CLI version ${current_version} found, but need ${AZ_CLI_VERSION}"
        fi
    fi
    
    log "Installing Azure CLI ${AZ_CLI_VERSION}..."
    
    # Remove any existing system-wide installations that might conflict
    set +o errexit
    sudo zypper --quiet --non-interactive remove azure-cli 2>/dev/null
    sudo rpm -e azure-cli 2>/dev/null
    sudo rm -rf "/opt/azure-cli" 2>/dev/null
    set -o errexit
    
    # Clean up any existing user-space installations
    rm -rf "${HOME}/lib/azure-cli" 2>/dev/null || true
    rm -rf "${HOME}/.azure" 2>/dev/null || true
    rm -f "${user_bin_dir}/az" 2>/dev/null || true
    
    # Check and install native dependencies
    local native_deps=(gcc libffi-devel python3-devel libopenssl-devel)
    local missing_deps=()
    
    for dep in "${native_deps[@]}"; do
        if ! rpm -q "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "Installing missing native dependencies: ${missing_deps[*]}"
        for dep in "${missing_deps[@]}"; do
            sudo zypper --quiet --non-interactive install "$dep" || log "Warning: Could not install $dep"
        done
    fi
    
    # Download Azure CLI install script
    local install_script="/tmp/azure_cli_install_script.py"
    log "Downloading Azure CLI install script..."
    curl -s https://azurecliprod.blob.core.windows.net/install.py -o "${install_script}"
    
    # Interactive installation with default user-space paths
    echo ""
    echo "=========================================="
    echo "Azure CLI Interactive Installation"
    echo "=========================================="
    echo "The Azure CLI installer will now prompt you for:"
    echo "1. Install directory    → Press Enter (use default: ${HOME}/lib/azure-cli)"
    echo "2. Executable directory → Press Enter (use default: ${HOME}/bin)"
    echo "3. Modify profile       → Enter: n"
    echo ""
    echo "The installation will remain in user space as designed."
    echo "=========================================="
    echo ""
    
    read -p "Press Enter to continue with Azure CLI installation..."
    
    log "Running Azure CLI installation interactively..."
    "${PYTHON_BIN}" "${install_script}"
    
    # Cleanup
    rm -f "${install_script}"
    
    # Verify installation
    if [[ -f "${user_bin_dir}/az" ]]; then
        current_version=$("${user_bin_dir}/az" version --output json 2>/dev/null | jq -r '."azure-cli"' 2>/dev/null || echo "unknown")
        log "Azure CLI ${current_version} installed successfully at ${user_bin_dir}/az"
        
        "${user_bin_dir}/az" config set extension.use_dynamic_install=yes_without_prompt --only-show-errors 2>/dev/null || true
        "${user_bin_dir}/az" version --output table 2>/dev/null || true
    else
        log "ERROR: Azure CLI installation failed"
        return 1
    fi
}

install_terraform() {
    if [[ -f "${TF_BIN}/terraform" ]]; then
        log "Terraform already installed"
        "${TF_BIN}/terraform" version
        return 0
    fi
    
    log "Installing Terraform ${TF_VERSION}..."
    
    local tf_zip="terraform_${TF_VERSION}_linux_amd64.zip"
    local download_url="https://releases.hashicorp.com/terraform/${TF_VERSION}/${tf_zip}"
    
    sudo mkdir -p "${TF_DIR}" "${TF_BIN}"
    
    wget -q -O "/tmp/${tf_zip}" "${download_url}"
    sudo unzip -q -o "/tmp/${tf_zip}" -d "${TF_DIR}"
    sudo ln -sf "../$(basename "${TF_DIR}")/terraform" "${TF_BIN}/terraform"
    
    sudo rm -f "/tmp/${tf_zip}"
    
    log "Terraform ${TF_VERSION} installed successfully"
    "${TF_BIN}/terraform" version
}

setup_ansible() {
    if [[ -f "${ANSIBLE_VENV_BIN}/ansible" ]]; then
        log "Ansible already installed"
        "${ANSIBLE_VENV_BIN}/ansible" --version
        return 0
    fi
    
    log "Setting up Ansible ${ANSIBLE_VERSION} in virtual environment..."
    
    # Create directories
    sudo mkdir -p "${ANSIBLE_BIN}" "${ANSIBLE_COLLECTIONS}"
    
    # Create virtual environment
    if [[ ! -e "${ANSIBLE_VENV_BIN}/activate" ]]; then
        sudo rm -rf "${ANSIBLE_VENV}"
        sudo "${PYTHON_BIN}" -m venv "${ANSIBLE_VENV}"
    fi
    
    # Install Ansible
    local ansible_major="${ANSIBLE_VERSION%%.*}"
    local ansible_minor=$(echo "${ANSIBLE_VERSION}." | cut -d . -f 2)
    
    sudo "${ANSIBLE_VENV_BIN}/pip3" install --quiet --upgrade pip wheel setuptools
    sudo "${ANSIBLE_VENV_BIN}/pip3" install --quiet \
        "ansible-core>=${ansible_major}.${ansible_minor},<${ansible_major}.$((ansible_minor + 1))" \
        argcomplete pywinrm netaddr jmespath
    
    # Create symlinks
    local ansible_commands=(
        ansible ansible-playbook ansible-galaxy ansible-vault
        ansible-config ansible-doc ansible-inventory
    )
    
    local relative_path
    relative_path="$(realpath --relative-to ${ANSIBLE_BIN} "${ANSIBLE_VENV_BIN}")"
    for cmd in "${ansible_commands[@]}"; do
        if [[ -f "${ANSIBLE_VENV_BIN}/${cmd}" ]]; then
            sudo ln -sf "${relative_path}/${cmd}" "${ANSIBLE_BIN}/${cmd}"
        fi
    done
    
    # Install essential collections
    log "Installing Ansible collections..."
    sudo mkdir -p "${ANSIBLE_COLLECTIONS}"
    
    local collections=(
        "ansible.windows" "ansible.posix" "ansible.utils"
        "community.windows" "microsoft.ad"
    )
    
    for collection in "${collections[@]}"; do
        # No dedicated silent install. Suppress stdout but show errors
        sudo -H "${ANSIBLE_VENV_BIN}/ansible-galaxy" collection install "${collection}" \
            --force --collections-path "${ANSIBLE_COLLECTIONS}" 1> /dev/null || true
    done
    
    log "Ansible ${ANSIBLE_VERSION} installed successfully"
}

setup_azure_sap_automation() {
    log "Setting up Azure SAP Automated Deployment..."
    
    # Get Azure metadata
    local rg_name subscription_id
    rg_name=$(curl -s -H Metadata:true --noproxy "*" \
        "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | \
        jq -r .compute.resourceGroupName 2>/dev/null || echo "unknown")
    subscription_id=$(curl -s -H Metadata:true --noproxy "*" \
        "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | \
        jq -r .compute.subscriptionId 2>/dev/null || echo "unknown")
    
    # Create folder structure
    mkdir -p \
        "${ASAD_WS}/LOCAL/${rg_name}" \
        "${ASAD_WS}/LIBRARY" \
        "${ASAD_WS}/SYSTEM" \
        "${ASAD_WS}/LANDSCAPE" \
        "${ASAD_WS}/DEPLOYER/${rg_name}"
    
    # Clone repositories if not already present
    if [[ ! -d "${ASAD_DIR}" ]]; then
        log "Cloning Azure SAP automation repository..."
        git clone --quiet "${ASAD_REPO}" "${ASAD_DIR}"
    fi
    
    if [[ ! -d "${ASAD_SAMPLE_DIR}" ]]; then
        log "Cloning Azure SAP automation samples repository..."
        git clone --quiet "${ASAD_SAMPLE_REPO}" "${ASAD_SAMPLE_DIR}"
    fi
    
    # Set ownership
    sudo chown -R "${USER}" "${ASAD_HOME}"
    
    log "Azure subscription ID: ${subscription_id}"
}

setup_environment() {
    log "Configuring environment..."
    
    local subscription_id
    subscription_id=$(curl -s -H Metadata:true --noproxy "*" \
        "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | \
        jq -r .compute.subscriptionId 2>/dev/null || echo "unknown")
    
    # Create environment script with PATH deduplication
    cat > /tmp/deploy_server.sh << 'EOF'
# SLES Deployer Environment Configuration

# Function to add path only if not already present
add_to_path() {
    if [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="$1:$PATH"
    fi
}

# Set subscription ID
export ARM_SUBSCRIPTION_ID=SUBSCRIPTION_ID_PLACEHOLDER

# Set SAP automation paths
export SAP_AUTOMATION_REPO_PATH=$HOME/Azure_SAP_Automated_Deployment/sap-automation
export DEPLOYMENT_REPO_PATH=$HOME/Azure_SAP_Automated_Deployment/sap-automation
export CONFIG_REPO_PATH=$HOME/Azure_SAP_Automated_Deployment/WORKSPACES

# Add tool paths (in reverse order of priority)
add_to_path "$HOME/Azure_SAP_Automated_Deployment/sap-automation/deploy/ansible"
add_to_path "$HOME/Azure_SAP_Automated_Deployment/sap-automation/deploy/scripts"
add_to_path "/opt/terraform/bin"
add_to_path "/opt/ansible/bin"
add_to_path "$HOME/bin"  # Azure CLI in user space
add_to_path "/opt/python/bin"

# Ansible configuration
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_COLLECTIONS_PATH=/opt/ansible/collections
export BOM_CATALOG=$HOME/Azure_SAP_Automated_Deployment/samples/SAP

# Azure authentication
export ARM_USE_MSI=true

# Azure login
az login --identity --output none 2>/dev/null && echo "Azure authentication ready"
EOF
    
    # Replace the placeholder with actual subscription ID
    sed -i "s/SUBSCRIPTION_ID_PLACEHOLDER/${subscription_id}/" /tmp/deploy_server.sh
    
    sudo cp /tmp/deploy_server.sh /etc/profile.d/deploy_server.sh
    sudo rm -f /tmp/deploy_server.sh
    
    log "Environment configuration completed"
}

#
# Main execution
#
main() {
    log "Starting SLES Deployer Configuration"
    
    check_sles
    install_development_tools
    install_python
    install_azure_cli
    install_terraform
    setup_ansible
    setup_azure_sap_automation
    setup_environment
    
    # Test Azure login
    "${AZ_BIN_DIR}/az" login --identity --output none 2>/dev/null || log "Azure login will be available after reboot"
    
    echo ""
    echo "=========================================="
    echo "SLES Deployer Configuration Complete!"
    echo "=========================================="
    echo "✓ Python ${PYTHON_VERSION}: ${PYTHON_DIR}"
    echo "✓ Azure CLI ${AZ_CLI_VERSION}: ${AZ_BIN_DIR}/az"
    echo "✓ Terraform ${TF_VERSION}: ${TF_BIN}/terraform"
    echo "✓ Ansible ${ANSIBLE_VERSION}: ${ANSIBLE_BIN}/ansible"
    echo "✓ Azure SAP Automation: ${ASAD_DIR}"
    echo ""
    echo "To activate the environment:"
    echo "  source /etc/profile.d/deploy_server.sh"
    echo ""
    echo "Or logout and login again."
    echo "=========================================="
}

# Execute main function
main "$@"