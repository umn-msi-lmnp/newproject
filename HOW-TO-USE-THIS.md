# How to use this `newproject` repo

## Start a new research project

- Establish a project name
- Determine a location on MSI Tier 1 for the project dir


## Clone this repo

- Determine a good location for the project on MSI Tier 1.
- Move to that location (one level up).
- Clone this example `newproject` repo, renaming it to be your "PROJECT_NAME"

```
cd /home/GROUP/shared/ris/USER
git clone "git@github.umn.edu:lmnp/newproject.git" PROJECT_NAME
cd PROJECT_NAME
```

## Cleanup your new repo

- Remove the `newproject` .git folder (we don't want to sync with `newproject`)
- Remove the instructions file.


```
rm -rf .git
rm HOW-TO-USE-THIS.md
```

## Initialize this folder as a new git repo

```
git init
```

- Update your readme.md, changelog.md, etc.
- Add and commit changes to your new repo, via `git add` and `git commit`
- Create a new repo on GitHub.umn.edu
- Sync your changes to GitHub
