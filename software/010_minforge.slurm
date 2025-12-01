#!/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=4:00:00
#SBATCH --mem=32gb
#SBATCH --tmp=8gb
#SBATCH --error=%x.e%j
#SBATCH --output=%x.o%j
#SBATCH --export=MSIPROJECT
#SBATCH --mail-type=FAIL
#SBATCH --partition=msismall

set -euo pipefail

# Get project root and setup paths
if [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    # Running via SLURM - use submit directory
    PROJECT_ROOT="$(cd "${SLURM_SUBMIT_DIR}/.." && pwd)"
else
    # Running interactively - use script location
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
INSTALL_DIR="${PROJECT_ROOT}/software_build/miniforge"
MINIFORGE_VERSION="24.7.1-0"

echo "Installing Miniforge to ${INSTALL_DIR}"

# Create installation directory
mkdir -p "${PROJECT_ROOT}/software_build"

# Download and install if not already present
if [ ! -d "${INSTALL_DIR}" ]; then
    cd "${PROJECT_ROOT}/software_build"
    
    echo "Downloading Miniforge..."
    wget -q "https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-${MINIFORGE_VERSION}-Linux-x86_64.sh"
    
    echo "Installing Miniforge..."
    bash "Miniforge3-${MINIFORGE_VERSION}-Linux-x86_64.sh" -b -p "${INSTALL_DIR}"
    
    echo "Cleaning up installer..."
    rm "Miniforge3-${MINIFORGE_VERSION}-Linux-x86_64.sh"
    
    echo "Configuring conda to use project-local paths only..."
    cat > "${INSTALL_DIR}/.condarc" << CONDARC
channels:
  - conda-forge

envs_dirs:
  - ${INSTALL_DIR}/envs

pkgs_dirs:
  - ${INSTALL_DIR}/pkgs
CONDARC
    
    echo "Miniforge installed successfully!"
else
    echo "Miniforge already installed at ${INSTALL_DIR}"
fi

# Create apptainer cache directory structure
echo "Creating .apptainer directory for container builds..."
mkdir -p "${PROJECT_ROOT}/.apptainer/cache"
mkdir -p "${PROJECT_ROOT}/.apptainer/tmp"

echo "Done! All software will be self-contained in this project."
