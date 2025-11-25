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
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PICARD_SIF="${PROJECT_ROOT}/software_build/containers/picard.sif"
OUT_DIR="${PROJECT_ROOT}/code_out/demo_apptainer"

# Configure Apptainer to use project-local cache (not $HOME/.apptainer)
export APPTAINER_CACHEDIR="${PROJECT_ROOT}/.apptainer/cache"
export APPTAINER_TMPDIR="${PROJECT_ROOT}/.apptainer/tmp"

mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

echo "=== Apptainer Demo: Real-world usage patterns ==="

# Example 1: Basic execution (container can access current directory by default)
echo -e "\n1. Basic execution:"
apptainer exec "${PICARD_SIF}" picard --version

# Example 2: With bind mounts (map external directories into container)
# Common pattern: bind project data directories
echo -e "\n2. With bind mounts:"
apptainer exec \
    --bind "${PROJECT_ROOT}:/project" \
    --bind "${OUT_DIR}:/output" \
    "${PICARD_SIF}" \
    bash -c "echo 'Project root inside container:' && ls /project | head -5"

# Example 3: Running Picard tool with input/output
# Create a dummy SAM header for demo
cat > test_header.sam << 'HEADER'
@HD	VN:1.6	SO:coordinate
@SQ	SN:chr1	LN:248956422
@PG	ID:demo	PN:demo	VN:1.0
HEADER

echo -e "\n3. Running Picard ValidateSamFile:"
apptainer exec \
    --bind "${OUT_DIR}:/data" \
    --pwd /data \
    "${PICARD_SIF}" \
    picard ValidateSamFile \
    I=test_header.sam \
    MODE=SUMMARY \
    > validation_output.txt 2>&1 || true

# Example 4: With environment variables
echo -e "\n4. With custom environment variables:"
apptainer exec \
    --env JAVA_OPTS="-Xmx4g" \
    "${PICARD_SIF}" \
    bash -c 'echo "JAVA_OPTS set to: $JAVA_OPTS"'

# Example 5: Common apptainer flags
cat > apptainer_usage_notes.txt << 'NOTES'
Common Apptainer Usage Patterns
================================

Basic execution:
  apptainer exec container.sif <command>

With bind mounts:
  apptainer exec --bind /source:/dest container.sif <command>
  
Multiple bind mounts:
  apptainer exec \
    --bind /data:/data \
    --bind /scratch:/scratch \
    --bind /tmp:/tmp \
    container.sif <command>

Set working directory:
  apptainer exec --pwd /path/in/container container.sif <command>

Pass environment variables:
  apptainer exec --env VAR=value container.sif <command>
  apptainer exec --cleanenv container.sif <command>  # Clean environment

GPU support:
  apptainer exec --nv container.sif <command>  # NVIDIA GPU

Read-only container:
  apptainer exec --no-home --containall container.sif <command>

Interactive shell:
  apptainer shell container.sif
  apptainer shell --bind /data:/data container.sif

Run container's runscript:
  apptainer run container.sif [args]

Common bind mount patterns for HPC:
  --bind /home/$USER:/home/$USER     # Home directory
  --bind /scratch.global:/scratch    # Scratch space
  --bind $TMPDIR:/tmp                # Job temp directory
  --bind /path/to/data:/data         # Data directory

Notes:
- Current directory is automatically bound by default
- Home directory is automatically bound by default
- Use --no-home to disable home binding
- Use --containall for maximum isolation
NOTES

echo -e "\n=== Demo Complete ==="
echo "Results saved to: ${OUT_DIR}"
echo "  - apptainer_usage_notes.txt (reference guide)"
echo "  - validation_output.txt (Picard demo output)"
echo "  - test_header.sam (demo input file)"
