#!/bin/bash
# Setup script for conda1 environment (R environment)
# Usage:
#   source /path/to/project/software/use_conda1.sh
#
# Can be sourced multiple times and will switch from other conda environments

# Determine project root from script location (works when sourced with any path)
if [ -n "${BASH_SOURCE[0]}" ]; then
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
else
    # Fallback if BASH_SOURCE is not available
    PROJECT_ROOT="$(pwd)"
fi

# Force conda to use project-local paths only (not $HOME/.conda)
export CONDARC="${PROJECT_ROOT}/software_build/miniforge/.condarc"

# Tell reticulate which Python to use (prevents leiden from trying to create r-reticulate)
export RETICULATE_PYTHON="${PROJECT_ROOT}/software_build/miniforge/envs/conda1/bin/python"

# Prevent R from saving/restoring workspace
export R_SAVE_IMAGE=no
export R_RESTORE_HISTORY=no

# Check if conda is already initialized, if not, initialize it
if ! command -v conda &> /dev/null; then
    source "${PROJECT_ROOT}/software_build/miniforge/bin/activate"
fi

# Activate conda1 environment (will switch from current env if already in one)
conda activate conda1

echo "Activated conda environment: conda1"
