#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=4:00:00
#SBATCH --mem=32gb
#SBATCH --tmp=8gb
#SBATCH --error=%x.e%j
#SBATCH --output=%x.o%j
#SBATCH --export=NONE
#SBATCH --mail-type=FAIL
#SBATCH --partition=msismall

# ---------------------------------------------------------------------
# Version (set by make software)
# ---------------------------------------------------------------------
SEMANTIC_VERSION=
GIT_CURRENT_BRANCH=
GIT_LATEST_COMMIT=
GIT_LATEST_COMMIT_SHORT=
GIT_LATEST_COMMIT_DIRTY=
GIT_LATEST_COMMIT_DATETIME=
GIT_REMOTE=
GIT_WEB_URL=
GIT_LATEST_COMMIT_LINK=
VERSION_SHORT=

echo "SEMANTIC_VERSION=${SEMANTIC_VERSION}"

set -euo pipefail

# Set umask to write new files with 660 (rw-rw----) and dirs with 770 (rwxrwx---)
umask 007
printf "umask set to '%s', which is symbolically represented as '%s'\n" $(umask) $(umask -S)

# Function to reliably get script path
slurm_script_path() {
    local script_path

    # Only use scontrol if we're confident we're in a SLURM batch job
    # SLURM_SUBMIT_DIR is ONLY set by sbatch, not by stale variables
    # (Note: salloc/srun also set it, but we handle that with additional checks)
    if [[ -n "${SLURM_SUBMIT_DIR-}" ]] && [[ -n "${SLURM_JOB_ID-}" ]] && command -v scontrol >/dev/null 2>&1; then
        # Try to get the command from scontrol
        script_path="$(scontrol show job "$SLURM_JOB_ID" -o 2>/dev/null | sed -n 's/.*Command=\([^ ]*\).*/\1/p')"

        # Only use scontrol result if it's a valid script file (not "bash", not empty, and exists)
        # This filters out interactive sessions where Command=bash
        if [[ -n "$script_path" ]] && [[ "$script_path" != "bash" ]] && [[ -f "$script_path" ]]; then
            # scontrol returned a valid script path - likely running under sbatch
            script_path="$script_path"
        else
            # scontrol returned "bash" or invalid path - running interactively or stale vars
            script_path="${BASH_SOURCE[0]}"
        fi
    else
        # No SLURM vars or scontrol not available - use BASH_SOURCE
        script_path="${BASH_SOURCE[0]}"
    fi

    script_path="$(readlink -f "$script_path")"
    printf "%s\n" "$script_path"
}

# ---------------------------------------------------------------------
# Dynamic script-based paths
# ---------------------------------------------------------------------
SCRIPT_PATH="$(slurm_script_path)"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
SCRIPT_DIR_NAME="$(basename "$SCRIPT_DIR")"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"
SCRIPT_BASE="${SCRIPT_NAME%.slurm}"

# Derived paths (do not edit these)
OUTPUT_ROOT="${PARENT_DIR}/${SCRIPT_DIR_NAME}_out"
OUTPUT_DIR="${OUTPUT_ROOT}/${SCRIPT_BASE}"
INSTALL_DIR="${OUTPUT_DIR}/miniforge"
MINIFORGE_VERSION="${MINIFORGE_VERSION:-24.7.1-0}"

echo "Script: ${SCRIPT_NAME}"
echo "Installing Miniforge to ${INSTALL_DIR}"

# Rename existing output directory if it exists
if [ -d "${OUTPUT_DIR}" ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    OLD_DIR="${OUTPUT_ROOT}/${SCRIPT_BASE}_DELETE_THIS_${TIMESTAMP}"
    echo "Existing output directory found. Renaming to: ${SCRIPT_BASE}_DELETE_THIS_${TIMESTAMP}"
    mv "${OUTPUT_DIR}" "${OLD_DIR}"
fi

# Create output directory
mkdir -p "${OUTPUT_ROOT}"
mkdir -p "${OUTPUT_DIR}"
cd "${OUTPUT_DIR}"

# Download and install if not already present
if [ ! -d "${INSTALL_DIR}" ]; then

    echo "Downloading Miniforge..."
    INSTALLER="Miniforge3-${MINIFORGE_VERSION}-Linux-x86_64.sh"
    wget -q "https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/${INSTALLER}"

    # ---------------------------------------------------------------------
    # Remove the check on free disk space
    # ---------------------------------------------------------------------
    # panasas does not report the correct values when using the "df" command, and miniforge uses this
    # command to determine if there is enough space to install the tool. It errors out if it fails
    # this check. Therefore, we remove this check.
    echo "Modifying installer to remove disk space check..."
    INSTALLER_MODIFIED="${INSTALLER%.sh}_modified.sh"
    sed '/^if \[ "$free_disk_space_kb_with_buffer"/,/^fi/ s/^/#/' "${INSTALLER}" >"${INSTALLER_MODIFIED}"

    # ---------------------------------------------------------------------
    # Run the installer
    # ---------------------------------------------------------------------
    echo "Installing Miniforge..."
    bash --login "${INSTALLER_MODIFIED}" -b -p "${INSTALL_DIR}"

    echo "Cleaning up installer..."
    rm "${INSTALLER}" "${INSTALLER_MODIFIED}"

    echo "Configuring conda to use project-local paths only..."
    cat > "${INSTALL_DIR}/.condarc" << CONDARC
channels:
  - conda-forge

envs_dirs:
  - ${INSTALL_DIR}/envs

pkgs_dirs:
  - ${INSTALL_DIR}/pkgs
CONDARC

    echo "Miniforge installed successfully!"
else
    echo "Miniforge already installed at ${INSTALL_DIR}"
fi

# Create a local .conda directory to prevent reading from ~/.conda
mkdir -p "${INSTALL_DIR}/.conda"
touch "${INSTALL_DIR}/.conda/environments.txt"


# ---------------------------------------------------------------------
# Create a shell script to initialize conda in the current shell
# ---------------------------------------------------------------------

echo "Generating activation script..."
cat > "${OUTPUT_DIR}/use_miniforge.sh" << 'ACTIVATION_SCRIPT'
#!/usr/bin/env bash
# Auto-generated activation script for miniforge
# Generated by: miniforge build script
# DO NOT EDIT MANUALLY - will be regenerated when miniforge is rebuilt
#
# PLEASE NOTE:
# The code below is generally managed by conda init. Conda suggests running "conda init", which writes these lines to your
# bashrc file. That causes every shell you open to add this version of conda to your PATH and adds various conda helper functions
# to your shell environment.
#
# However, we work in HPC environments, and each user may not want to have conda installed in every shell they open.
# Instead, when we want conda available, we source this script in the shell we want to use conda in.
#
# This results in this shell being configured exactly as conda would normally do it (via bashrc). But it does not affect
# all your other shells, only this particular shell.

# ---------------------------------------------------------------------
# Check if script is being sourced or executed
# ---------------------------------------------------------------------
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "ERROR: This script must be sourced, not executed directly."
    echo ""
    echo "Usage:"
    echo "  source ${BASH_SOURCE[0]}"
    echo ""
    echo "Or:"
    echo "  . ${BASH_SOURCE[0]}"
    echo ""
    echo "Do NOT run it as:"
    echo "  ./${BASH_SOURCE[0]##*/}  # WRONG!"
    echo "  bash ${BASH_SOURCE[0]##*/}  # WRONG!"
    echo ""
    echo "Explanation:"
    echo "  This script modifies your current shell environment (PATH, conda functions, etc.)."
    echo "  Executing it directly creates a subshell that exits immediately, losing all changes."
    echo "  Sourcing it runs the commands in your current shell, preserving the environment."
    exit 1
fi

# Derive paths from this activation script location
ACTIVATION_SCRIPT_PATH="${BASH_SOURCE[0]}"
ACTIVATION_DIR="$(cd -- "$(dirname -- "${ACTIVATION_SCRIPT_PATH}")" && pwd -P)"
MINIFORGE_DIR="${ACTIVATION_DIR}/miniforge"
SOFTWARE_OUT="$(dirname "${ACTIVATION_DIR}")"

# ---------------------------------------------------------------------
# Block system-level conda/python to ensure isolation
# ---------------------------------------------------------------------

# Unset conda-related environment variables from other installations
unset CONDA_EXE CONDA_PREFIX CONDA_PYTHON_EXE CONDA_SHLVL CONDA_DEFAULT_ENV
unset CONDA_PROMPT_MODIFIER _CE_CONDA _CE_M

# Prevent conda from using user home directory
unset CONDA_ENVS_PATH CONDA_PKGS_DIRS

# ---------------------------------------------------------------------
# Set up miniforge environment variables for complete isolation
# ---------------------------------------------------------------------

# Override ALL conda configuration paths by setting explicit environment variables BEFORE conda initializes
# These take precedence over any .condarc files (including ~/.condarc)
export CONDA_ENVS_DIRS="${MINIFORGE_DIR}/envs"
export CONDA_PKGS_DIRS="${MINIFORGE_DIR}/pkgs"

# Force conda to use project-local .condarc only (not $HOME/.conda or ~/.condarc)
export CONDARC="${MINIFORGE_DIR}/.condarc"

# Set SSL certificate path for conda
export CONDA_SSL_VERIFY="${MINIFORGE_DIR}/ssl/cacert.pem"

# Prevent conda from tracking envs in ~/.conda/environments.txt
# By setting CONDA_USER_BASE, we prevent conda from reading/writing to HOME directory
export CONDA_ROOT="${MINIFORGE_DIR}"
export CONDA_USER_BASE="${MINIFORGE_DIR}"

# ---------------------------------------------------------------------
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# ---------------------------------------------------------------------


# Make miniforge base tools available immediately
# Add miniforge bin to PATH so python, mamba, etc. are immediately available
# if the conda init step needs them.
case ":${PATH}:" in
    *":${MINIFORGE_DIR}/bin:"*) ;;
    *) export PATH="${MINIFORGE_DIR}/bin:${PATH}" ;;
esac

 if __conda_setup="$("${MINIFORGE_DIR}/bin/conda" shell.bash hook 2>&1)"; then
     eval "$__conda_setup"
 else
     printf 'conda hook failed:\n%s\n' "$__conda_setup" >&2
     if [ -f "${MINIFORGE_DIR}/etc/profile.d/conda.sh" ]; then
         . "${MINIFORGE_DIR}/etc/profile.d/conda.sh"
     fi
 fi
 unset __conda_setup

if [ -f "${MINIFORGE_DIR}/etc/profile.d/mamba.sh" ]; then
    . "${MINIFORGE_DIR}/etc/profile.d/mamba.sh"
fi


# ---------------------------------------------------------------------
# Force complete isolation from HOME directory conda after initialization
# ---------------------------------------------------------------------

# Re-export these after conda init to ensure they override conda's defaults
# This prevents conda from looking in ~/.conda/envs or reading ~/.conda/environments.txt
export CONDA_ENVS_DIRS="${MINIFORGE_DIR}/envs"
export CONDA_PKGS_DIRS="${MINIFORGE_DIR}/pkgs"

# ---------------------------------------------------------------------
# Make miniforge base tools available immediately
# ---------------------------------------------------------------------
# Add miniforge bin to PATH so python, mamba, etc. are immediately available
# even if you do not activate a base or other env. For example, after sourcing
# this script, "python" will be from inside your miniforge install dir.
# This is another defense approach to force PATH to use miniforge before anything else.
# This does NOT activate the base environment, just makes tools accessible
# When you activate a specific env (e.g., conda1), that env's bin will take precedence
case ":${PATH}:" in
    *":${MINIFORGE_DIR}/bin:"*) ;;
    *) export PATH="${MINIFORGE_DIR}/bin:${PATH}" ;;
esac

# ---------------------------------------------------------------------
# Prevent Python leakage from home directory
# ---------------------------------------------------------------------
# Unset PYTHONPATH to prevent home directory Python packages from being imported
unset PYTHONPATH PYTHONHOME PYTHONSTARTUP

# Unset PYTHONUSERBASE to prevent ~/.local/lib/python* from being used
unset PYTHONUSERBASE

# Set Python to ignore user site-packages (prevents ~/.local/lib/python* from being used)
export PYTHONNOUSERSITE=1

# ---------------------------------------------------------------------
# Configure R to use environment-specific directories (not home directory)
# ---------------------------------------------------------------------
# Note: These will be set to environment-specific paths when conda env is activated
# For now, set them to prevent any home directory access
export R_ENVIRON_USER="/dev/null"
export R_PROFILE_USER="/dev/null"
export R_LIBS_USER="${MINIFORGE_DIR}/.R_libs_base"
export R_USER="${SOFTWARE_OUT}"
export R_CHECK_ENVIRON="FALSE"

# ---------------------------------------------------------------------
# Configure R/reticulate (will be updated per-environment on activate)
# ---------------------------------------------------------------------
export RETICULATE_AUTOCONFIGURE=0
export RETICULATE_MINICONDA_ENABLED=FALSE
export RETICULATE_PYTHON="${MINIFORGE_DIR}/bin/python"

# Create a wrapper to filter conda env list output
# This is necessary because conda reads ~/.conda/environments.txt regardless of our settings
# We save the original conda function and wrap it carefully
_original_conda_function="$(declare -f conda)"
eval "$(echo "${_original_conda_function}" | sed 's/conda ()/__original_conda ()/')"

# Ensure conda resolves with Miniforge base python first in PATH.
# This avoids env python shebang issues when conda is called inside an active env.
__run_original_conda() {
    PATH="${MINIFORGE_DIR}/bin:${PATH}" __original_conda "$@"
}

conda() {
    if [ "$1" = "activate" ]; then
        local nounset_was_on=0
        local conda_status=0
        case "$-" in
            *u*)
                nounset_was_on=1
                set +u
                ;;
        esac
        # Activate the environment first
        __run_original_conda "$@"
        conda_status=$?
        if [ "$nounset_was_on" -eq 1 ]; then
            set -u
        fi
        if [ "$conda_status" -ne 0 ]; then
            return "$conda_status"
        fi
        # After activation, update environment-specific paths
        if [ -n "${CONDA_PREFIX}" ]; then
            # Set Python path for reticulate
            export RETICULATE_PYTHON="${CONDA_PREFIX}/bin/python"

            # Set R paths to be environment-specific (not home directory, not shared)
            export R_ENVIRON_USER="${CONDA_PREFIX}/.Renviron"
            export R_PROFILE_USER="${CONDA_PREFIX}/.Rprofile"
            export R_LIBS_USER="${CONDA_PREFIX}/R_libs"

            # Set reticulate cache to be environment-specific
            export RETICULATE_CACHE_DIR="${CONDA_PREFIX}/.cache/reticulate"
        fi
    elif [ "$1" = "deactivate" ]; then
        local nounset_was_on=0
        local conda_status=0
        case "$-" in
            *u*)
                nounset_was_on=1
                set +u
                ;;
        esac
        # Deactivate the environment
        __run_original_conda "$@"
        conda_status=$?
        if [ "$nounset_was_on" -eq 1 ]; then
            set -u
        fi
        if [ "$conda_status" -ne 0 ]; then
            return "$conda_status"
        fi
        # Reset to base/neutral paths
        export RETICULATE_PYTHON="${MINIFORGE_DIR}/bin/python"
        export R_ENVIRON_USER="/dev/null"
        export R_PROFILE_USER="/dev/null"
        export R_LIBS_USER="${MINIFORGE_DIR}/.R_libs_base"
        export RETICULATE_CACHE_DIR="${MINIFORGE_DIR}/.cache/reticulate"
    elif [ "$1" = "env" ] && [ "$2" = "list" ]; then
        # Show only header and environments in this repo
        __run_original_conda env list | awk '$1 ~ /^#/ { print }'
        __run_original_conda env list | awk -v root="${MINIFORGE_DIR}" '
            $1 ~ /^#/ { next }
            index($NF, root) { print }
        '
    else
        # Pass through all other conda commands to the original function
        __run_original_conda "$@"
    fi
}

# Print a message to the shell
printf "\n"
printf "%s\n" "----------------------------------"
printf "PLEASE NOTE: This shell has been configured to run conda (and mamba).\n\n"
printf "Miniforge installation: %s\n\n" "${MINIFORGE_DIR}"
printf "Python/conda status:\n"
printf "  python, mamba, conda commands are now available (from miniforge base)\n"
printf "  No conda environment is active yet (CONDA_PREFIX is not set)\n"
printf "  To get environment-specific packages, activate an environment:\n"
printf "    conda activate <env_name>\n\n"
printf "To stop using this version of these tools, exit the shell:\n"
printf "exit\n\n"
printf "Useful commands:\n"
printf "conda env list                   # List conda environments available to you\n"
printf "conda activate ENV               # Activate an env by name\n"
printf "conda deactivate                 # Deactivate your current conda env\n"
printf "mamba create -n MYNAME MYTOOL    # Create a new env, using the faster 'mamba' solver\n\n"
printf "Available environments:\n"
available_envs="$(conda env list | awk '
    $1 ~ /^#/ { next }
    ++count == 1 { next }
    { print }
')"
if [ -n "$available_envs" ]; then
    printf "%s\n" "$available_envs"
else
    printf "  No environments created yet\n"
fi
printf "\nQuick start:\n"
# Dynamically show first two available environments, or generic message if none exist
ENV_LIST="$(conda env list | awk -v root="${MINIFORGE_DIR}/envs/" '
    $1 ~ /^#/ { next }
    index($NF, root) { print $1 }
' | head -2)"
if [ -n "$ENV_LIST" ]; then
    while IFS= read -r env_name; do
        [ -n "$env_name" ] && printf "  conda activate %s\n" "$env_name"
    done <<< "$ENV_LIST"
else
    printf "  conda activate <env_name>  # Replace <env_name> with your environment name\n"
fi
printf "%s\n\n" "----------------------------------"
ACTIVATION_SCRIPT

chmod +x "${OUTPUT_DIR}/use_miniforge.sh"
echo "Activation script created at: ${OUTPUT_DIR}/use_miniforge.sh"
echo ""
echo "Done! Miniforge output is in ${OUTPUT_DIR}/"
