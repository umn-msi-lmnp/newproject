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
MINIFORGE_DIR="${PROJECT_ROOT}/software_build/miniforge"
ENV_FILE="${PROJECT_ROOT}/software/conda1.yml"

# Force conda to use project-local paths only (not $HOME/.conda)
export CONDARC="${MINIFORGE_DIR}/.condarc"

# Activate miniforge
source "${MINIFORGE_DIR}/bin/activate"

# Check if environment already exists
ENV_EXISTS=$(conda env list | grep -c "^conda1 " || true)

if [ "$ENV_EXISTS" -gt 0 ]; then
    # Check if running with TTY (interactive) or not
    if [ -t 0 ]; then
        # Running interactively - prompt for confirmation
        echo "Environment conda1 already exists."
        read -p "Do you want to delete and rebuild it? (yes/no): " response
        if [ "$response" = "yes" ]; then
            echo "Removing environment conda1..."
            mamba env remove -n conda1 -y
        else
            echo "Aborting. Environment not modified."
            exit 0
        fi
    else
        # Running non-interactively - automatically remove and rebuild
        echo "Environment conda1 already exists. Running non-interactively - automatically removing and rebuilding..."
        mamba env remove -n conda1 -y
    fi
fi

echo "Building conda environment: conda1"
mamba env create -f "${ENV_FILE}"

echo "Done! Environment conda1 is ready."

# Export environment specifications for record keeping
echo "Exporting environment specification for record keeping..."
EXPORT_DIR="${PROJECT_ROOT}/software_build/miniforge_env_exports"
mkdir -p "${EXPORT_DIR}"

conda env export -n conda1 > "${EXPORT_DIR}/conda1_export.yml"
conda env export --from-history -n conda1 > "${EXPORT_DIR}/conda1_export_from_history.yml"

echo "Environment exports saved to ${EXPORT_DIR}/"
