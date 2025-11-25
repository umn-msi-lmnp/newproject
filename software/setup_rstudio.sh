#!/bin/bash
# Setup script for RStudio Server via Open OnDemand
# Usage in OOD "Custom Environment" box:
#   cd /path/to/project && source software/setup_rstudio.sh

PROJECT_ROOT="$(pwd)"

cat <<HEADER
===================================================================
Setting up RStudio environment
===================================================================
Project: ${PROJECT_ROOT}
HEADER

# Force conda to use project-local paths only (not $HOME/.conda)
export CONDARC="${PROJECT_ROOT}/software_build/miniforge/.condarc"

# Activate conda env1 (R environment)
source "${PROJECT_ROOT}/software_build/miniforge/bin/activate" env1

cat <<FOOTER
Environment: env1 activated
R location: $(which R)
R version: $(R --version | head -n1)

R library paths:
$(R --slave -e "cat(paste(.libPaths(), collapse='\n'))")

R session info:
$(R --slave -e "if(require(sessioninfo, quietly=TRUE)) session_info() else sessionInfo()")

RStudio will use R from this conda environment.
All packages are self-contained in this project.
===================================================================
FOOTER
