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

# Get project root
if [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    PROJECT_ROOT="$(cd "${SLURM_SUBMIT_DIR}/.." && pwd)"
else
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Setup output directory
OUT_DIR="${PROJECT_ROOT}/code_out/demo_analysis"
mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

echo "=========================================="
echo "Demo 1: conda1 (R and Python)"
echo "=========================================="
# Activate conda1 environment (includes R and Python)
source "${PROJECT_ROOT}/software_out/011_conda1/use_conda1.sh"

# Run R analysis
echo "Running R analysis..."
Rscript --vanilla "${PROJECT_ROOT}/code/demo_analysis.R"

# Run Python analysis
echo "Running Python analysis..."
python "${PROJECT_ROOT}/code/demo_analysis.py"

echo ""
echo "=========================================="
echo "Demo 2: conda2 (samtools)"
echo "=========================================="
# Switch to conda2 environment
source "${PROJECT_ROOT}/software_out/012_conda2/use_conda2.sh"

# Demo samtools - create a simple BAM header and validate
echo "Testing samtools availability..."
samtools --version | head -n 1

echo "Creating test SAM file..."
cat > test.sam << 'EOF'
@HD	VN:1.6	SO:coordinate
@SQ	SN:chr1	LN:248956422
@PG	ID:demo	PN:demo	VN:1.0
EOF

echo "Converting SAM to BAM with samtools..."
samtools view -bS test.sam > test.bam
samtools view -H test.bam
echo "Samtools demo complete!"

echo ""
echo "=========================================="
echo "Demo 3: Apptainer (Picard)"
echo "=========================================="
# Configure Apptainer
export APPTAINER_CACHEDIR="${PROJECT_ROOT}/.apptainer/cache"
export APPTAINER_TMPDIR="${PROJECT_ROOT}/.apptainer/tmp"

CONTAINER_SIF="${PROJECT_ROOT}/software_out/021_apptainer1/apptainer1.sif"
PROJECT_REAL_PATH="$(realpath "${PROJECT_ROOT}")"

echo "Testing Picard in Apptainer container..."
apptainer exec "${CONTAINER_SIF}" picard --version

echo "Running Picard ValidateSamFile..."
apptainer exec \
    --bind "${PROJECT_REAL_PATH}:${PROJECT_REAL_PATH}" \
    "${CONTAINER_SIF}" \
    picard ValidateSamFile \
    I="${OUT_DIR}/test.sam" \
    MODE=SUMMARY \
    > picard_validation.txt 2>&1 || true

echo "Apptainer demo complete!"

echo ""
echo "=========================================="
echo "All demos completed successfully!"
echo "Results saved to: ${OUT_DIR}"
echo "=========================================="
