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

# Setup environment - Apptainer container for Picard
if [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    # Running via SLURM - use submit directory
    PROJECT_ROOT="$(cd "${SLURM_SUBMIT_DIR}/.." && pwd)"
else
    # Running interactively - use script location
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
CONTAINER_SIF="${PROJECT_ROOT}/software_build/apptainers/apptainer1.sif"
OUT_DIR="${PROJECT_ROOT}/code_out/demo_apptainer1"

# Configure Apptainer to use project-local cache (not $HOME/.apptainer)
export APPTAINER_CACHEDIR="${PROJECT_ROOT}/.apptainer/cache"
export APPTAINER_TMPDIR="${PROJECT_ROOT}/.apptainer/tmp"

# Get the real path (resolves symlinks)
PROJECT_REAL_PATH="$(realpath "${PROJECT_ROOT}")"

mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

echo "=== Apptainer Demo: Bind mount patterns ==="
echo "Project root: ${PROJECT_REAL_PATH}"

# Example 1: Basic execution (container can access current directory by default)
echo -e "\n1. Basic execution:"
apptainer exec "${CONTAINER_SIF}" picard --version

# Example 2: Bind project root to same path inside container
# This prevents path mismatch issues when using full paths as arguments
echo -e "\n2. Bind project to same path (recommended pattern):"
apptainer exec \
    --bind "${PROJECT_REAL_PATH}:${PROJECT_REAL_PATH}" \
    "${CONTAINER_SIF}" \
    bash -c "echo 'Inside container, project is accessible at:' && ls ${PROJECT_REAL_PATH} | head -5"

# Example 3: Running Picard with files using full paths
# Create a dummy SAM header for demo
cat > test_header.sam << 'HEADER'
@HD	VN:1.6	SO:coordinate
@SQ	SN:chr1	LN:248956422
@PG	ID:demo	PN:demo	VN:1.0
HEADER

echo -e "\n3. Running Picard with full paths:"
apptainer exec \
    --bind "${PROJECT_REAL_PATH}:${PROJECT_REAL_PATH}" \
    "${CONTAINER_SIF}" \
    picard ValidateSamFile \
    I="${OUT_DIR}/test_header.sam" \
    MODE=SUMMARY \
    > validation_output.txt 2>&1 || true

# Example 4: With environment variables
echo -e "\n4. With custom environment variables:"
apptainer exec \
    --bind "${PROJECT_REAL_PATH}:${PROJECT_REAL_PATH}" \
    --env JAVA_OPTS="-Xmx4g" \
    "${CONTAINER_SIF}" \
    bash -c 'echo "JAVA_OPTS set to: $JAVA_OPTS"'

# Example 5: Usage reference
cat > apptainer_usage_notes.txt << 'NOTES'
Common Apptainer Usage Patterns
================================

Recommended: Bind project to same path (avoids path issues)
  PROJECT_PATH="$(realpath /path/to/project)"
  apptainer exec --bind "${PROJECT_PATH}:${PROJECT_PATH}" container.sif <command>

Basic execution:
  apptainer exec container.sif <command>

Multiple bind mounts:
  apptainer exec \
    --bind /data:/data \
    --bind /scratch:/scratch \
    container.sif <command>

Set working directory:
  apptainer exec --pwd /path/in/container container.sif <command>

Pass environment variables:
  apptainer exec --env VAR=value container.sif <command>

Interactive shell:
  apptainer shell --bind "${PROJECT_PATH}:${PROJECT_PATH}" container.sif

Notes:
- Binding to the same path inside/outside container prevents path mismatch issues
- Current directory is automatically bound by default
- Home directory is automatically bound by default
- Use realpath to resolve symlinks before binding
NOTES

echo -e "\n=== Demo Complete ==="
echo "Results saved to: ${OUT_DIR}"
echo "  - apptainer_usage_notes.txt (reference guide)"
echo "  - validation_output.txt (Picard demo output)"
echo "  - test_header.sam (demo input file)"
