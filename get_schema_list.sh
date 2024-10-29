#!/bin/bash

# Target directory for the schemas
SCHEMA_DIRECTORY=$_SCHEMA_DIRECTORY

# Initialise the lists
NEW_SCHEMA_FILEPATHS=()
ERROR_DIRECTORIES=()

# checkout the repository
git clone $_REPOSITORY_URL /workspace/repo
cd /workspace/repo

# Get the list of newly added files in the commit
NEW_FILES=$(git diff --name-only --diff-filter=A HEAD~1 HEAD)

# Filter the files to only include new schemas in the schema_directory
NEW_SCHEMAS=$(echo "${NEW_FILES}" | grep "^$SCHEMA_DIRECTORY/")

# Iterate over each subdirectory in the schema_directory
for SUBDIR in $(find $SCHEMA_DIRECTORY -mindepth 1 -maxdepth 1 -type d); do
    # Get the list of new schemas in the subdirectory
    NEW_SCHEMAS_IN_SUBDIR=$(echo "$NEW_SCHEMAS" | grep "^$SUBDIR/")

    # Count the number of new schemas in the subdirectory
    NUM_NEW_SCHEMAS=$(echo "$NEW_SCHEMAS_IN_SUBDIR" | wc -l)

    if [ "$NUM_NEW_SCHEMAS" -eq 1 ]; then
    # If there is exactly one new schema, add it to the NEW_SCHEMA_FILEPATHS list
    NEW_SCHEMA_FILEPATHS+=("$NEW_SCHEMAS_IN_SUBDIR")
    elif [ "$NUM_NEW_SCHEMAS" -gt 1 ]; then
    # If there is more than one new schema, add the subdirectory to the ERROR_DIRECTORIES list
    ERROR_DIRECTORIES+=("$SUBDIR")
    fi
done

# Write the lists to environment variable files
echo "NEW_SCHEMA_FILEPATHS=${NEW_SCHEMA_FILEPATHS[@]}" > /workspace/new_schema_filepaths.env
echo "ERROR_DIRECTORIES=${ERROR_DIRECTORIES[@]}" > /workspace/error_directories.env