#!/bin/bash

# Get last commit hash from previous time the script was run
source /workspace/last_commit_hash.env

# Initialise the empty lists
NEW_SCHEMA_FILEPATHS=()
ERROR_DIRECTORIES=()

# cd into the repository
cd /workspace

git checkout $BRANCH_NAME

git fetch --unshallow

# Get the latest commit SHA
LATEST_COMMIT=$(git rev-parse HEAD)
if [ $? -ne 0 ]; then
  echo "Failed to retrieve the latest commit. Exiting."
  exit 1
fi

# Write the latest commit hash to an environment variable file
echo ${LATEST_COMMIT} > /workspace/latest_commit_hash.env
chmod 644 /workspace/latest_commit_hash.env

NEW_FILES=$(git diff --name-only --diff-filter=A "$LAST_COMMIT_HASH" "$LATEST_COMMIT")

# Check if there are new files in the latest commit
if [ -z "$NEW_FILES" ]; then
  echo "No new files found in the latest commit."
  exit 0
else
  echo "Found new files in the latest commit."
fi

# Convert NEW_FILES to an array
IFS=$'\n' read -r -d '' -a NEW_FILES_ARRAY <<< "$NEW_FILES"

SCHEMA_LIST=()
# Filter the list of new files to only include schema files
for file in "${NEW_FILES_ARRAY[@]}"; do
    if [[ "$file" == "schemas/"* ]]; then
        # add the file to SCHEMA_LIST array
        SCHEMA_LIST+=("$file")
    fi
done

# Add the schema files to the NEW_SCHEMA_FILEPATHS list if the subdirectory only contains 1 new file
for schema in "${SCHEMA_LIST[@]}"; do
    # Get the subdirectory of the schema file
    subdirectory=$(dirname "$schema")
    # Get the number of new files in the subdirectory
    num_files=$(git diff --name-only --diff-filter=A "$LAST_COMMIT_HASH" "$LATEST_COMMIT" "$subdirectory" | wc -l)
    if [ $num_files -eq 1 ]; then
        NEW_SCHEMA_FILEPATHS+=("$schema")
    else
        ERROR_DIRECTORIES+=("$subdirectory")
    fi
done

# Write the lists to environment variable files
# Ensure no empty elements are written to the file
if [ ${#NEW_SCHEMA_FILEPATHS[@]} -gt 0 ]; then
    printf "%s\n" "${NEW_SCHEMA_FILEPATHS[@]}" > /workspace/new_schema_filepaths.env
    chmod 644 /workspace/new_schema_filepaths.env
fi
chmod 644 /workspace/new_schema_filepaths.env
echo "ERROR_DIRECTORIES=${ERROR_DIRECTORIES}" > /workspace/error_directories.env
chmod 644 /workspace/error_directories.env

sleep 5

echo "New schema filepaths:"
for new_schema_filepath in "${NEW_SCHEMA_FILEPATHS[@]}"; do
    echo "New schema: $new_schema_filepath"
done