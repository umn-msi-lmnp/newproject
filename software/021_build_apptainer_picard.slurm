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
DEF_FILE="${PROJECT_ROOT}/software/picard.def"
CONTAINER_DIR="${PROJECT_ROOT}/software_build/containers"

# Configure Apptainer to use project-local cache (not $HOME/.apptainer)
export APPTAINER_CACHEDIR="${PROJECT_ROOT}/.apptainer/cache"
export APPTAINER_TMPDIR="${PROJECT_ROOT}/.apptainer/tmp"

echo "Building Apptainer container: picard.sif"
echo "Using project cache: ${APPTAINER_CACHEDIR}"

# Build container
mkdir -p "${CONTAINER_DIR}"
mkdir -p "${APPTAINER_CACHEDIR}"
mkdir -p "${APPTAINER_TMPDIR}"
cd "${CONTAINER_DIR}"
apptainer build --fakeroot picard.sif "${DEF_FILE}"

echo "Done! Container ready at ${CONTAINER_DIR}/picard.sif"
