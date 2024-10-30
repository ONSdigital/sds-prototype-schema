#!/bin/bash

# Target directory for the schemas
SCHEMA_DIRECTORY=$_SCHEMA_DIRECTORY
REPOSITORY_URL=$_REPOSITORY_URL
REPOSITORY_NAME=$_REPOSITORY_NAME

# Initialise the lists
NEW_SCHEMA_FILEPATHS=()
ERROR_DIRECTORIES=()

# checkout the repository - BRANCH_NAME is a default substituion in Cloud Build
# git clone https://github.com/ONSdigital/sds-prototype-schema.git /workspace
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
  # If there is no previous commit, assume all files in the schema_directory are new
  NEW_FILES=$(find "$SCHEMA_DIRECTORY" -type f)
    echo "No previous commit found. Assuming all files in the schema_directory are new."
fi

echo "Filtering new files in the schema_directory."
# Filter the files to only include new schemas in the schema_directory
NEW_SCHEMAS=$(echo "${NEW_FILES}" | grep "^$SCHEMA_DIRECTORY/")


# Iterate over each subdirectory in the schema_directory
for subdir in $(find "$SCHEMA_DIRECTORY" -mindepth 1 -maxdepth 1 -type d); do
    echo "Checking subdirectory: $subdir"
    # Get the list of new schemas in the subdirectory
    NEW_SCHEMAS_IN_SUBDIR=$(echo "$NEW_SCHEMAS" | grep "^$subdir/")

    # Count the number of new schemas in the subdirectory
    NUM_NEW_SCHEMAS=$(echo "$NEW_SCHEMAS_IN_SUBDIR" | wc -l)

    if [ "$NUM_NEW_SCHEMAS" -eq 1 ]; then
        # If there is exactly one new schema, add it to the NEW_SCHEMA_FILEPATHS list
        NEW_SCHEMA_FILEPATHS+=("$NEW_SCHEMAS_IN_SUBDIR")
    elif [ "$NUM_NEW_SCHEMAS" -gt 1 ]; then
        # If there is more than one new schema, add the subdirectory to the ERROR_DIRECTORIES list
        ERROR_DIRECTORIES+=("$subdir")
    fi
done

# Write the lists to environment variable files
echo "NEW_SCHEMA_FILEPATHS=${NEW_SCHEMA_FILEPATHS[@]}" > /workspace/new_schema_filepaths.env
echo "ERROR_DIRECTORIES=${ERROR_DIRECTORIES[@]}" > /workspace/error_directories.env