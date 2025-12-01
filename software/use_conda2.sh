#!/bin/bash
# Setup script for conda2 environment (Python environment)
# Usage:
#   source /path/to/project/software/use_conda2.sh
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

# Check if conda is already initialized, if not, initialize it
if ! command -v conda &> /dev/null; then
    source "${PROJECT_ROOT}/software_build/miniforge/bin/activate"
fi

# Activate conda2 environment (will switch from current env if already in one)
conda activate conda2

echo "Activated conda environment: conda2"
