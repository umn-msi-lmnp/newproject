#!/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=4:00:00
#SBATCH --mem=32gb
#SBATCH --tmp=8gb
#SBATCH --error=%x.e%j
#SBATCH --output=%x.o%j
#SBATCH --export=NONE
#SBATCH --mail-type=FAIL
#SBATCH --partition=msismall

set -euo pipefail

# Function to reliably get script directory
slurm_script_dir() {
  local script_path
  if [[ -n "${SLURM_JOB_ID-}" ]]; then
    script_path="$(scontrol show job "$SLURM_JOB_ID" -o | sed -n 's/.*Command=\([^ ]*\).*/\1/p')"
  else
    script_path="${BASH_SOURCE[0]}"
  fi
  script_path="$(readlink -f "$script_path")"
  dirname "$script_path"
}

# Get project root and setup paths
# Since script is in PROJECT_ROOT/software/, get parent directory
SCRIPT_DIR="$(slurm_script_dir)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Output directory matching this script's name
OUTPUT_DIR="${PROJECT_ROOT}/software_out/021_apptainer1"

# Input files
DEF_FILE="${PROJECT_ROOT}/software/apptainer1.def"

# Configure Apptainer to use project-local cache (not $HOME/.apptainer)
export APPTAINER_CACHEDIR="${PROJECT_ROOT}/.apptainer/cache"
export APPTAINER_TMPDIR="${PROJECT_ROOT}/.apptainer/tmp"

echo "Building Apptainer container: apptainer1.sif"
echo "Using project cache: ${APPTAINER_CACHEDIR}"

# Rename existing output directory if it exists
if [ -d "${OUTPUT_DIR}" ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    OLD_DIR="${PROJECT_ROOT}/software_out/021_apptainer1_DELETE_THIS_${TIMESTAMP}"
    echo "Existing output directory found. Renaming to: 021_apptainer1_DELETE_THIS_${TIMESTAMP}"
    mv "${OUTPUT_DIR}" "${OLD_DIR}"
fi

# Build container
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${APPTAINER_CACHEDIR}"
mkdir -p "${APPTAINER_TMPDIR}"
cd "${OUTPUT_DIR}"
apptainer build --fakeroot apptainer1.sif "${DEF_FILE}"

echo "Done! Container ready at ${OUTPUT_DIR}/apptainer1.sif"
