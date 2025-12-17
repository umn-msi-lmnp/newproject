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

# ---------------------------------------------------------------------
# Extract conda environment name from script filename
# ---------------------------------------------------------------------
# Script name format: NNN_envname.slurm -> envname
# Examples: 011_conda1.slurm -> conda1, 015_my_env.slurm -> my_env

# When running via SLURM, use SLURM_JOB_NAME (contains original script name)
# When running interactively, use BASH_SOURCE[0]
if [ -n "${SLURM_JOB_ID:-}" ] && [ -n "${SLURM_JOB_NAME:-}" ]; then
    SCRIPT_NAME="${SLURM_JOB_NAME}"
else
    SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
fi

SCRIPT_BASE="${SCRIPT_NAME%.slurm}"           # Remove .slurm extension
CONDA_ENV_NAME="${SCRIPT_BASE#[0-9][0-9][0-9]_}"  # Remove NNN_ prefix

echo "Building conda environment: ${CONDA_ENV_NAME}"
echo "Script: ${SCRIPT_NAME}"

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

# Path to miniforge (installed by 010_miniforge.slurm)
MINIFORGE_DIR="${PROJECT_ROOT}/software_out/010_miniforge/miniforge"

# Output directory matching this script's base name (NNN_envname)
OUTPUT_DIR="${PROJECT_ROOT}/software_out/${SCRIPT_BASE}"

# Environment file will be generated in the output directory
ENV_FILE="${OUTPUT_DIR}/environment.yml"

# Rename existing output directory if it exists
if [ -d "${OUTPUT_DIR}" ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    OLD_DIR="${PROJECT_ROOT}/software_out/${SCRIPT_BASE}_DELETE_THIS_${TIMESTAMP}"
    echo "Existing output directory found. Renaming to: ${SCRIPT_BASE}_DELETE_THIS_${TIMESTAMP}"
    mv "${OUTPUT_DIR}" "${OLD_DIR}"
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# ---------------------------------------------------------------------
# Generate conda environment YAML file
# ---------------------------------------------------------------------
echo "Generating environment.yml for ${CONDA_ENV_NAME}..."
cat > "${ENV_FILE}" << EOF
name: ${CONDA_ENV_NAME}
channels:
  - r
  - bioconda
  - conda-forge
dependencies:
  - r-base=4.4.0
  - r-tidyverse
  - r-ggplot2
  - bioconductor-deseq2
  - r-seurat>=5
  - r-leiden
  - r-reticulate
  - r-glue
  - r-sessioninfo
  - python>=3.9
  - pip
  - pip:
      - numpy
      - pandas
      - python-igraph
      - leidenalg
EOF

echo "Environment YAML saved to: ${ENV_FILE}"

# ---------------------------------------------------------------------
# Set up complete isolation from HOME directory conda
# (Same isolation approach as use_miniforge.sh)
# ---------------------------------------------------------------------

# Override ALL conda configuration paths
export CONDA_ENVS_DIRS="${MINIFORGE_DIR}/envs"
export CONDA_PKGS_DIRS="${MINIFORGE_DIR}/pkgs"

# Force conda to use project-local .condarc only
export CONDARC="${MINIFORGE_DIR}/.condarc"

# Set SSL certificate path for conda
export CONDA_SSL_VERIFY="${MINIFORGE_DIR}/ssl/cacert.pem"

# Prevent conda from tracking envs in ~/.conda/environments.txt
export CONDA_ROOT="${MINIFORGE_DIR}"
export CONDA_USER_BASE="${MINIFORGE_DIR}"

# Activate miniforge (initialize conda in this build script)
source "${MINIFORGE_DIR}/bin/activate"

# Check if environment already exists (avoid grep due to set -e)
ENV_EXISTS=0
while IFS= read -r line; do
    if [[ "$line" =~ ^${CONDA_ENV_NAME}[[:space:]] ]]; then
        ENV_EXISTS=1
        break
    fi
done < <(conda env list)

if [ "$ENV_EXISTS" -gt 0 ]; then
    # Check if running with TTY (interactive) or not
    if [ -t 0 ]; then
        # Running interactively - prompt for confirmation
        echo "Environment ${CONDA_ENV_NAME} already exists."
        read -p "Do you want to delete and rebuild it? (yes/no): " response
        if [ "$response" = "yes" ]; then
            echo "Removing environment ${CONDA_ENV_NAME}..."
            mamba env remove -n "${CONDA_ENV_NAME}" -y
        else
            echo "Aborting. Environment not modified."
            exit 0
        fi
    else
        # Running non-interactively - automatically remove and rebuild
        echo "Environment ${CONDA_ENV_NAME} already exists. Running non-interactively - automatically removing and rebuilding..."
        mamba env remove -n "${CONDA_ENV_NAME}" -y
    fi
fi

echo "Building conda environment: ${CONDA_ENV_NAME}"
mamba env create -f "${ENV_FILE}"

echo "Done! Environment ${CONDA_ENV_NAME} is ready."

# Create conda activation/deactivation scripts for LD_LIBRARY_PATH
echo "Creating conda activation/deactivation scripts..."
CONDA_ENV_PREFIX="${MINIFORGE_DIR}/envs/${CONDA_ENV_NAME}"

# Detect gcc version dynamically
GCC_LIB_PATH=""
if [ -d "${CONDA_ENV_PREFIX}/lib/gcc/x86_64-conda-linux-gnu" ]; then
    # Directory exists, look for version subdirectory
    for version_dir in "${CONDA_ENV_PREFIX}/lib/gcc/x86_64-conda-linux-gnu"/*; do
        if [ -d "$version_dir" ]; then
            GCC_VERSION=$(basename "$version_dir")
            echo "Detected gcc version: $GCC_VERSION"
            GCC_LIB_PATH="${CONDA_ENV_PREFIX}/lib/gcc/x86_64-conda-linux-gnu/${GCC_VERSION}:"
            break
        fi
    done
fi

if [ -z "$GCC_LIB_PATH" ]; then
    echo "Note: gcc not found in ${CONDA_ENV_NAME}, skipping gcc library path"
fi

# Create activate.d directory and script
mkdir -p "${CONDA_ENV_PREFIX}/etc/conda/activate.d"
cat > "${CONDA_ENV_PREFIX}/etc/conda/activate.d/env_vars.sh" << EOF
#!/bin/sh

# Save the current LD_LIBRARY_PATH so we can restore it on deactivate
export LD_LIBRARY_PATH_BACKUP="\${LD_LIBRARY_PATH:-}"

# Add conda environment library paths
# Priority order: R libs (if present), general libs, gcc libs (if present), then system
if [ -d "\${CONDA_PREFIX}/lib/R/lib" ]; then
    export LD_LIBRARY_PATH="\${CONDA_PREFIX}/lib/R/lib:\${CONDA_PREFIX}/lib:${GCC_LIB_PATH}\${LD_LIBRARY_PATH}"
else
    export LD_LIBRARY_PATH="\${CONDA_PREFIX}/lib:${GCC_LIB_PATH}\${LD_LIBRARY_PATH}"
fi
EOF

chmod +x "${CONDA_ENV_PREFIX}/etc/conda/activate.d/env_vars.sh"

# Create deactivate.d directory and script
mkdir -p "${CONDA_ENV_PREFIX}/etc/conda/deactivate.d"
cat > "${CONDA_ENV_PREFIX}/etc/conda/deactivate.d/env_vars.sh" << 'EOF'
#!/bin/sh

# Restore the original LD_LIBRARY_PATH
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH_BACKUP}"
unset LD_LIBRARY_PATH_BACKUP
EOF

chmod +x "${CONDA_ENV_PREFIX}/etc/conda/deactivate.d/env_vars.sh"

echo "Conda activation/deactivation scripts created."

# Export environment specifications for record keeping
echo "Exporting environment specification for record keeping..."
conda env export -n "${CONDA_ENV_NAME}" > "${OUTPUT_DIR}/env_export.yml"
conda env export --from-history -n "${CONDA_ENV_NAME}" > "${OUTPUT_DIR}/env_export_from_history.yml"

echo "Environment exports saved to ${OUTPUT_DIR}/"
echo ""
echo "Done! All ${CONDA_ENV_NAME} outputs are in ${OUTPUT_DIR}/"
echo ""
echo "To use this environment:"
echo "  source ${PROJECT_ROOT}/software_out/010_miniforge/use_miniforge.sh"
echo "  conda activate ${CONDA_ENV_NAME}"
