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

# Output directory matching this script's name
OUTPUT_DIR="${PROJECT_ROOT}/software_out/010_miniforge"
INSTALL_DIR="${OUTPUT_DIR}/miniforge"
MINIFORGE_VERSION="24.7.1-0"

echo "Installing Miniforge to ${INSTALL_DIR}"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Download and install if not already present
if [ ! -d "${INSTALL_DIR}" ]; then
    cd "${OUTPUT_DIR}"
    
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

echo "Done! Miniforge output is in ${OUTPUT_DIR}/"
