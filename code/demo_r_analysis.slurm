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

# Setup environment - Activate conda env1 (R environment)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CONDARC="${PROJECT_ROOT}/software_build/miniforge/.condarc"
source "${PROJECT_ROOT}/software_build/miniforge/bin/activate" env1

# Run R script
Rscript --vanilla "${PROJECT_ROOT}/code/demo_r_analysis.R"

