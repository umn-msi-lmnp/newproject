# Agents

This file contains guidelines and conventions for agents working on this repository.

## Code Style

### Character Encoding
- **Code files**: Must use only ASCII characters 32-127 (printable ASCII characters)
- **Test scripts**: Must use only ASCII characters 32-127 (printable ASCII characters)
- **Markdown files**: May use Unicode characters for documentation purposes

### General Guidelines
- Follow existing code conventions in the repository
- Use consistent indentation and formatting
- Write clear, readable code with meaningful variable names
- Add comments only when explicitly requested
- Avoid introducing unnecessary complexity
- Prefer snakecase (all lowercase with underscores) for filenames, but allow flexibility

## Repository Structure

This repository contains:
- `code/`: Analysis scripts that are version controlled
- `code_out/`: Each code script generates a corresponding dir in the code_out dir
- `software/`: Build scripts and environment configurations
- `software_build/`: Generated software environments that could be deleted and recreated if necessary
- Configuration files for SLURM, conda, and Apptainer
- `GETTING_STARTED.md`: Contains full project structure documentation

## Testing

Before committing changes, ensure all code follows the character encoding requirements and existing style conventions. Use informative commit messages with added details in the description section.
