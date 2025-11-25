# How to use this template repo

This is a template for starting new bioinformatics projects with reproducible software environments.

## Quick Start

### 1. Clone this template

```bash
cd /projects/standard/GROUP/shared/ris/USER
git clone "git@github.umn.edu:lmnp/newproject.git" my_project_name
cd my_project_name
```

### 2. Make it your own

```bash
# Remove template git history
rm -rf .git

# Initialize as new repo
git init

# Update readme.md and changelog.md with your project info
```

### 3. Build software environments

Run these in order:

```bash
cd software

# Build miniforge (local conda installer)
sbatch 010_build_minforge.slurm

# Build R environment (tidyverse, ggplot2, etc.)
sbatch 011_build_conda_environment1.slurm

# Build Python environment (biopython, pandas, etc.)
sbatch 012_build_conda_environment2.slurm

# Build Picard container (optional)
sbatch 021_build_apptainer_picard.slurm
```

Each script can also be run as a shell script: `bash 010_build_minforge.slurm`

## Using the environments

### In SLURM scripts

Each environment activates with 2 lines at the top of your script:

**For R (env1):**
```bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/software_build/miniforge/bin/activate" env1
```

**For Python (env2):**
```bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/software_build/miniforge/bin/activate" env2
```

**For Apptainer (Picard):**
```bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PICARD_SIF="${PROJECT_ROOT}/software_build/containers/picard.sif"
apptainer exec "${PICARD_SIF}" picard <command>
```

### In RStudio Server (Open OnDemand)

When launching RStudio via Open OnDemand, use the "Custom Environment" box:

```bash
cd /full/path/to/my_project_name && source software/setup_rstudio.sh
```

This activates env1 (R environment) before RStudio starts.

To verify in RStudio:
```r
.libPaths()           # Should show env1 path first
library(tidyverse)    # Should load successfully
```

## Demo scripts

Three example scripts are included in `code/`:

```bash
cd code
sbatch demo_r_analysis.slurm        # R plotting demo
sbatch demo_python_analysis.slurm  # Python sequence analysis demo
sbatch demo_apptainer.slurm    # Apptainer container demo (bind mounts, env vars)
```

## Project structure

```
my_project_name/
  software/               Scripts to build environments
    010_build_minforge.slurm
    011_build_conda_environment1.slurm
    012_build_conda_environment2.slurm
    021_build_apptainer_picard.slurm
    environment1.yml      R packages
    environment2.yml      Python packages
    picard.def            Picard container definition
    setup_rstudio.sh      For RStudio OOD sessions
  
  software_build/         Built software (NOT in git)
    miniforge/            Local conda installation
      envs/env1/          R environment
      envs/env2/          Python environment
    containers/
      picard.sif          Picard container
  
  code/                   Your analysis scripts (in git)
    demo_r_analysis.R
    demo_r_analysis.slurm
    demo_python_analysis.py
    demo_python_analysis.slurm
    demo_apptainer.slurm
  
  code_out/               Analysis outputs (NOT in git)
    demo_r_analysis/
    demo_python_analysis/
    demo_apptainer/
```

## Key features

- **Portable**: Uses relative paths. Clone anywhere and it works.
- **Reproducible**: Specific package versions in environment.yml files.
- **No modules needed**: Self-contained conda environments.
- **Easy to use**: 2-line activation in each script.
- **Self-contained**: All software stays in project directory, not $HOME.

## Self-contained environments

All software is installed within this project directory. Nothing goes to your home directory.

### Software locations

```
software_build/
  env_exports/
    environment1_export.yml                    # Full env1 snapshot (all packages)
    environment1_export_from_history.yml       # env1 user intent (explicit packages)
    environment2_export.yml                    # Full env2 snapshot
    environment2_export_from_history.yml       # env2 user intent
  miniforge/
    envs/
      env1/          # R environment with all R packages
      env2/          # Python environment with all Python packages
    pkgs/            # Conda package cache (shared across environments)
  containers/
    picard.sif       # Picard Tools Apptainer container

.apptainer/
  cache/             # Apptainer container build cache
  tmp/               # Apptainer temporary build files
```

### Specific locations

**R packages** (from env1):
```
software_build/miniforge/envs/env1/lib/R/library/
```

**Python packages** (from env2):
```
software_build/miniforge/envs/env2/lib/python3.X/site-packages/
```

**Apptainer cache** (all container layers):
```
.apptainer/cache/
```

### Benefits

- The project is fully portable
- No conflicts with other conda installations
- Can be deleted without affecting $HOME
- Complete isolation from system packages
- Only system dependency: Apptainer executable

### What this means

When you activate env1 or env2, you're using R/Python and ALL packages from within this project directory. Nothing is shared with or stored in your $HOME directory. The entire software environment can be deleted and rebuilt from scratch using the scripts in `software/`.

### Environment exports for record keeping

After building each environment, two export files are automatically created in `software_build/env_exports/`:

1. **Full export** (`environment1_export.yml`): Complete snapshot of ALL installed packages with exact versions and build strings. Platform-specific. Use this to recreate the exact environment.

2. **History export** (`environment1_export_from_history.yml`): Only the packages you explicitly requested (matches your environment1.yml). Cross-platform. Use this to understand what was intentionally installed.

These exports are build artifacts (not tracked in git) that document exactly what was built. They're useful for:
- Debugging environment issues
- Reproducing exact environments
- Comparing environments over time
- Documentation purposes

## Modifying environments

### Adding R packages

Edit `software/environment1.yml`, then rebuild:
```bash
sbatch software/011_build_conda_environment1.slurm
```

### Adding Python packages to env2

Edit `software/environment2.yml`, then rebuild:
```bash
sbatch software/012_build_conda_environment2.slurm
```

### Adding pip packages to env1 (R environment)

env1 includes Python and pip, allowing you to install Python packages needed by R packages (e.g., leidenalg for r-leiden).

Edit `software/environment1.yml` and add to the `pip:` section:
```yaml
dependencies:
  - r-base=4.3
  - r-leiden
  - python>=3.9
  - pip
  - pip:
      - leidenalg        # Add your pip packages here
      - another-package  # Add more as needed
```

Then rebuild:
```bash
sbatch software/011_build_conda_environment1.slurm
```

**Where pip packages are installed:**
```
software_build/miniforge/envs/env1/lib/python3.X/site-packages/
```

**Why this works:**
- Conda environments ARE virtual environments
- No separate venv needed
- pip installs to env1's isolated site-packages
- Everything stays within the project
- Fully reproducible from environment1.yml

**Verification after rebuild:**
```bash
source software_build/miniforge/bin/activate env1
which pip     # Should show env1's pip
python -c "import leidenalg; print(leidenalg.__version__)"
```

The `--force` flag will replace existing environments.
