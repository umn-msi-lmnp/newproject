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
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MINIFORGE_DIR="${PROJECT_ROOT}/software_build/miniforge"
ENV_FILE="${PROJECT_ROOT}/software/environment1.yml"

# Force conda to use project-local paths only (not $HOME/.conda)
export CONDARC="${MINIFORGE_DIR}/.condarc"

echo "Building conda environment: env1"

# Activate miniforge and create environment
source "${MINIFORGE_DIR}/bin/activate"
mamba env create -f "${ENV_FILE}"

echo "Done! Environment env1 is ready."

# Export environment specifications for record keeping
echo "Exporting environment specification for record keeping..."
EXPORT_DIR="${PROJECT_ROOT}/software_build/env_exports"
mkdir -p "${EXPORT_DIR}"

conda env export -n env1 > "${EXPORT_DIR}/environment1_export.yml"
conda env export --from-history -n env1 > "${EXPORT_DIR}/environment1_export_from_history.yml"

echo "Environment exports saved to ${EXPORT_DIR}/"
