# How to Use This Template Repository

This is a template for starting new bioinformatics projects with reproducible, self-contained software environments.

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

# Update readme.md with your project information
# Update changelog.md with your project start date
```

### 3. Build software environments

```bash
cd software
sbatch 010_minforge.slurm  # Build miniforge (required for conda)
sbatch 011_conda1.slurm    # Build R environment
sbatch 012_conda2.slurm    # Build Python environment
```

Each script can also be run as a shell script: `bash 010_minforge.slurm`

## Three Methods for Installing Software

This template demonstrates three methods for managing software dependencies:

### Method 1: Conda Environments (01x series)

Build custom conda environments from YAML specifications.

```bash
sbatch 010_minforge.slurm  # Build miniforge (local conda installer)
sbatch 011_conda1.slurm    # Build R environment (tidyverse, ggplot2, etc.)
sbatch 012_conda2.slurm    # Build Python environment (biopython, pandas, etc.)
```

**When to use:**
- You need R or Python packages
- You want full control over package versions
- You need a mix of conda and pip packages

**Configuration files:**
- `software/conda1.yml` - R environment specification
- `software/conda2.yml` - Python environment specification

### Method 2: Build Custom Apptainer Containers (02x series)

Build containers from definition files for maximum reproducibility.

```bash
sbatch 021_apptainer1.slurm  # Build Picard container from apptainer1.def
```

**When to use:**
- You need tools not available in conda
- You want maximum reproducibility
- You need to share exact environments with collaborators

**Configuration files:**
- `software/apptainer1.def` - Picard container definition

### Method 3: Download Prebuilt Containers (03x series)

Download existing containers from Docker Hub or other registries.

```bash
sbatch 031_deepvariant.slurm  # Download DeepVariant from Docker Hub
```

**When to use:**
- Standard tools with official Docker images exist
- You want to use the "official" version of a tool
- You need to quickly get started without building

## Using the Environments

### In SLURM Scripts

Activate conda environments with a single line:

**For R (conda1):**
```bash
source software/use_conda1.sh
```

**For Python (conda2):**
```bash
source software/use_conda2.sh
```

**Or using absolute paths:**
```bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/software/use_conda1.sh"
```

**For Apptainer containers:**
```bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_SIF="${PROJECT_ROOT}/software_build/apptainers/apptainer1.sif"
PROJECT_REAL_PATH="$(realpath "${PROJECT_ROOT}")"
apptainer exec --bind "${PROJECT_REAL_PATH}:${PROJECT_REAL_PATH}" "${CONTAINER_SIF}" picard <command>
```

**Switching between conda environments:**

The `use_conda*.sh` scripts can be sourced multiple times in the same session:

```bash
source software/use_conda1.sh  # Activate conda1
# ... do R work ...

source software/use_conda2.sh  # Switch to conda2
# ... do Python work ...
```

### In RStudio Server (Open OnDemand)

When launching RStudio via Open OnDemand, use the "Custom Environment" box:

```bash
cd /full/path/to/my_project_name && source software/use_conda1.sh
```

To verify in RStudio:
```r
.libPaths()           # Should show conda1 path first
library(tidyverse)    # Should load successfully
```

## Demo Scripts

Three example scripts demonstrate each software method:

```bash
cd code
sbatch demo_r_analysis.slurm        # Uses conda1 (R environment)
sbatch demo_python_analysis.slurm  # Uses conda2 (Python environment)
sbatch demo_apptainer1.slurm       # Uses apptainer1.sif (Picard container)
```

## Project Structure

```
my_project_name/
  software/               Build scripts for environments
    010_minforge.slurm    # Method 1: Build conda (required first)
    011_conda1.slurm      # Method 1: Build R conda environment
    012_conda2.slurm      # Method 1: Build Python conda environment
    021_apptainer1.slurm  # Method 2: Build custom container
    031_deepvariant.slurm # Method 3: Download prebuilt container
    conda1.yml            # R environment specification
    conda2.yml            # Python environment specification
    apptainer1.def        # Picard container definition
    use_conda1.sh         # Helper to activate conda1
    use_conda2.sh         # Helper to activate conda2
  
  software_build/         Built software (NOT in git)
    miniforge/
      envs/conda1/        # R environment
      envs/conda2/        # Python environment
    miniforge_env_exports/
      conda1_export.yml   # Full snapshot of conda1
      conda2_export.yml   # Full snapshot of conda2
    apptainers/
      apptainer1.sif      # Custom-built Picard container
      deepvariant.sif     # Downloaded DeepVariant container
  
  .apptainer/             Apptainer build cache (NOT in git)
    cache/
    tmp/
  
  code/                   Your analysis scripts (in git)
  code_out/               Analysis outputs (NOT in git, reproducible)
  input/                  Input data or symlinks
  meta/                   Project metadata
```

## Self-Contained Environments

All software is installed within this project directory. **Nothing goes to your home directory.**

### Software Locations

**R packages** (from conda1):
```
software_build/miniforge/envs/conda1/lib/R/library/
```

**Python packages** (from conda2):
```
software_build/miniforge/envs/conda2/lib/python3.X/site-packages/
```

**Apptainer containers:**
```
software_build/apptainers/
  apptainer1.sif
  deepvariant.sif
```

**Apptainer cache:**
```
.apptainer/cache/
```

### Benefits

- **Portable**: Clone anywhere and rebuild identical environments
- **Reproducible**: Specific package versions in YAML/definition files
- **Self-contained**: All software in project directory, not $HOME
- **No conflicts**: Independent of system-wide installations
- **Deletable**: Can delete `software_build/` and rebuild from scratch

### System Dependencies

Only one system-level dependency required:
- **Apptainer** (for building and running containers)

Everything else (conda, mamba, R, Python, all packages) is installed locally.

## Modifying Environments

### Adding R Packages to conda1

1. Edit `software/conda1.yml`
2. Add packages under `dependencies:`
3. Rebuild: `sbatch software/011_conda1.slurm`

### Adding Python Packages to conda2

1. Edit `software/conda2.yml`
2. Add packages under `dependencies:`
3. Rebuild: `sbatch software/012_conda2.slurm`

### Adding pip Packages to conda1 (R environment)

conda1 includes Python for R packages that need it (e.g., `r-leiden` needs `leidenalg`).

1. Edit `software/conda1.yml`
2. Add to the `pip:` section:
   ```yaml
   dependencies:
     - r-leiden
     - python>=3.9
     - pip
     - pip:
         - leidenalg
         - another-package
   ```
3. Rebuild: `sbatch software/011_conda1.slurm`

**Why this works:**
- Conda environments ARE virtual environments
- No separate venv needed
- pip installs to conda1's isolated site-packages
- Everything stays within the project
- Fully reproducible from conda1.yml

### Modifying Containers

**For custom-built containers:**
1. Edit `software/apptainer1.def`
2. Rebuild: `sbatch software/021_apptainer1.slurm`

**For downloaded containers:**
1. Edit `software/031_deepvariant.slurm` to change version
2. Re-download: `sbatch software/031_deepvariant.slurm`

## Environment Exports (Record Keeping)

After building each conda environment, two export files are automatically created in `software_build/miniforge_env_exports/`:

1. **Full export** (`conda1_export.yml`): 
   - Complete snapshot of ALL installed packages
   - Exact versions and build strings
   - Platform-specific
   - Use to recreate exact environment

2. **History export** (`conda1_export_from_history.yml`):
   - Only explicitly requested packages
   - Matches your conda1.yml
   - Cross-platform
   - Use to understand intent

These are not tracked in git but are useful for:
- Debugging environment issues
- Reproducing exact environments
- Comparing environments over time
- Documentation

## Key Features

- **Portable**: Uses relative paths. Clone anywhere and it works.
- **Reproducible**: Specific package versions in configuration files.
- **No modules needed**: Self-contained conda environments.
- **Easy to use**: Single-line activation in scripts.
- **Self-contained**: All software stays in project directory, not $HOME.
- **Three methods**: Conda, custom containers, or downloaded containers.

## Naming Conventions

### Software Build Scripts (software/ directory)

- **01x**: Conda environments
  - `010_minforge.slurm` - Build miniforge
  - `011_conda1.slurm` - Build conda environment 1
  - `012_conda2.slurm` - Build conda environment 2

- **02x**: Custom Apptainer containers (built from .def files)
  - `021_apptainer1.slurm` - Build custom container 1
  - `022_apptainer2.slurm` - Build custom container 2

- **03x**: Downloaded containers (from registries)
  - `031_deepvariant.slurm` - Download container 1
  - `032_another.slurm` - Download container 2

### Demo Scripts (code/ directory)

Demo scripts match their corresponding software:
- `demo_r_analysis.slurm` - Demonstrates conda1 (R)
- `demo_python_analysis.slurm` - Demonstrates conda2 (Python)
- `demo_apptainer1.slurm` - Demonstrates apptainer1.sif

### Output Directories

Output directory names match their script names:
- `code/demo_r_analysis.slurm` → `code_out/demo_r_analysis/`
- `code/my_analysis.slurm` → `code_out/my_analysis/`

## Troubleshooting

**Q: Conda activation fails**
A: Make sure you built miniforge first: `sbatch software/010_minforge.slurm`

**Q: R can't find packages**
A: Check `.libPaths()` in R. The conda1 path should be first.

**Q: Apptainer can't access files**
A: Use `--bind` to mount directories. See `code/demo_apptainer1.slurm` for examples.

**Q: Want to delete and rebuild everything?**
A: `rm -rf software_build/ .apptainer/` then rebuild from `software/` scripts.
