#!/bin/bash
set -euo pipefail

echo "=== Testing Path Resolution Logic ==="
echo ""

# Simulate SLURM environment
SLURM_JOB_ID="12345"
SLURM_JOB_NAME="011_conda1.slurm"
SLURM_SUBMIT_DIR="/projects/standard/lmnp/knut0297/lmnp_org/newproject/software"

echo "SLURM_JOB_ID: ${SLURM_JOB_ID}"
echo "SLURM_JOB_NAME: ${SLURM_JOB_NAME}"
echo "SLURM_SUBMIT_DIR: ${SLURM_SUBMIT_DIR}"
echo ""

# Extract script name
if [ -n "${SLURM_JOB_ID:-}" ] && [ -n "${SLURM_JOB_NAME:-}" ]; then
    SCRIPT_NAME="${SLURM_JOB_NAME}"
else
    SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
fi

echo "SCRIPT_NAME: ${SCRIPT_NAME}"

# Determine PROJECT_ROOT
if [ -n "${SLURM_JOB_ID:-}" ] && [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    if [ -f "${SLURM_SUBMIT_DIR}/${SCRIPT_NAME}" ]; then
        echo "Case 1: sbatch was run from software/ directory"
        PROJECT_ROOT="$(cd "${SLURM_SUBMIT_DIR}/.." && pwd)"
    elif [ -f "${SLURM_SUBMIT_DIR}/software/${SCRIPT_NAME}" ]; then
        echo "Case 2: sbatch was run from project root"
        PROJECT_ROOT="${SLURM_SUBMIT_DIR}"
    else
        echo "Case 3: Fallback"
        PROJECT_ROOT="${SLURM_SUBMIT_DIR}"
    fi
else
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

echo "PROJECT_ROOT: ${PROJECT_ROOT}"
echo ""

SCRIPT_BASE="${SCRIPT_NAME%.slurm}"
CONDA_ENV_NAME="${SCRIPT_BASE#[0-9][0-9][0-9]_}"
OUTPUT_DIR="${PROJECT_ROOT}/software_out/${SCRIPT_BASE}"

echo "SCRIPT_BASE: ${SCRIPT_BASE}"
echo "CONDA_ENV_NAME: ${CONDA_ENV_NAME}"
echo "OUTPUT_DIR: ${OUTPUT_DIR}"
echo ""

if [[ "${OUTPUT_DIR}" == *"/newproject/software_out/011_conda1" ]]; then
    echo "✓ CORRECT! Output directory is in the right place"
else
    echo "✗ WRONG! Output directory: ${OUTPUT_DIR}"
fi
