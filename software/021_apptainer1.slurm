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
DEF_FILE="${PROJECT_ROOT}/software/apptainer1.def"
CONTAINER_DIR="${PROJECT_ROOT}/software_build/apptainers"

# Configure Apptainer to use project-local cache (not $HOME/.apptainer)
export APPTAINER_CACHEDIR="${PROJECT_ROOT}/.apptainer/cache"
export APPTAINER_TMPDIR="${PROJECT_ROOT}/.apptainer/tmp"

echo "Building Apptainer container: apptainer1.sif"
echo "Using project cache: ${APPTAINER_CACHEDIR}"

# Build container
mkdir -p "${CONTAINER_DIR}"
mkdir -p "${APPTAINER_CACHEDIR}"
mkdir -p "${APPTAINER_TMPDIR}"
cd "${CONTAINER_DIR}"
apptainer build --fakeroot apptainer1.sif "${DEF_FILE}"

echo "Done! Container ready at ${CONTAINER_DIR}/apptainer1.sif"
