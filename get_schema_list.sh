#!/bin/bash

# Initialise the lists
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

# Check if there is a previous commit
if git rev-parse "${LATEST_COMMIT}~1" >/dev/null 2>&1; then
  # Get the list of newly added files in the latest commit
  NEW_FILES=$(git diff --name-only --diff-filter=A "${LATEST_COMMIT}~1" "${LATEST_COMMIT}")
  echo "Found new files in the latest commit."
else
  echo "No previous commit found. Exiting."
  exit 0
fi

# Convert NEW_FILES to an array
IFS=$'\n' read -r -d '' -a NEW_FILES_ARRAY <<< "$NEW_FILES"

for file in "${NEW_FILES_ARRAY[@]}"; do
    echo "New file: $file"
done

schema_list = ()
# Filter the list of new files to only include schema files
for file in "${NEW_FILES_ARRAY[@]}"; do
    if [[ "$file" == "schemas/"* ]]; then
        # add the file to schema_list array
        schema_list+=("$file")
    fi
done

for schema in "${schema_list[@]}"; do
    echo "Schema: $schema"
done

# Add the schema files to the NEW_SCHEMA_FILEPATHS list if the subdirectory only contains 1 new file
for schema in "${schema_list[@]}"; do
    # Get the subdirectory of the schema file
    subdirectory=$(dirname "$schema")
    # Get the number of new files in the subdirectory
    num_files=$(git diff --name-only --diff-filter=A "${LATEST_COMMIT}~1" "${LATEST_COMMIT}" "$subdirectory" | wc -l)
    if [ $num_files -eq 1 ]; then
        NEW_SCHEMA_FILEPATHS+=("$schema")
    else
        ERROR_DIRECTORIES+=("$subdirectory")
    fi
done

# Write the lists to environment variable files
echo "NEW_SCHEMA_FILEPATHS=${NEW_SCHEMA_FILEPATHS[@]}" > /workspace/new_schema_filepaths.env
chmod 644 /workspace/new_schema_filepaths.env
echo "ERROR_DIRECTORIES=${ERROR_DIRECTORIES[@]}" > /workspace/error_directories.env
chmod 644 /workspace/error_directories.env

for new_schema_filepath in "${NEW_SCHEMA_FILEPATHS[@]}"; do
    echo "New schema: $new_schema_filepath"
done