#!/bin/bash

# Ensure required environment variables are set
if [ -z "$_SCHEMA_DIRECTORY" ]; then
  echo "SCHEMA_DIRECTORY is not set. Exiting."
  exit 1
fi

# Target directory for the schemas
SCHEMA_DIRECTORY=$_SCHEMA_DIRECTORY

# Initialise the lists
NEW_SCHEMA_FILEPATHS=()
ERROR_DIRECTORIES=()

# cd into the repository
cd /workspace || exit

# Ensure we are on the correct branch (e.g., main)
git checkout $BRANCH_NAME

# Fetch all history to ensure we have previous commits
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

# Debugging output to check the contents of NEW_FILES
echo "NEW_FILES:"
echo "${NEW_FILES}"

echo "Filtering new files in the schema_directory."
# Filter the files to only include new schemas in the schema_directory
NEW_SCHEMAS=$(echo "${NEW_FILES}" | grep "^${SCHEMA_DIRECTORY}/")
# Debugging output to check the contents of NEW_SCHEMAS
echo "NEW_SCHEMAS:"
echo "${NEW_SCHEMAS}"

# Iterate over each subdirectory in the schema_directory
for subdir in $(find "$SCHEMA_DIRECTORY" -mindepth 1 -maxdepth 1 -type d); do
    echo "Checking subdirectory: $subdir"
    # Get the list of new schemas in the subdirectory
    NEW_SCHEMAS_IN_SUBDIR=$(echo "$NEW_SCHEMAS" | grep "^$subdir/")

    # Debugging output to check the contents of NEW_SCHEMAS_IN_SUBDIR
    echo "NEW_SCHEMAS_IN_SUBDIR:"
    echo "${NEW_SCHEMAS_IN_SUBDIR}"

    # Count the number of new schemas in the subdirectory
    NUM_NEW_SCHEMAS=$(echo "$NEW_SCHEMAS_IN_SUBDIR" | wc -l)

    if [ "$NUM_NEW_SCHEMAS" -eq 1 ]; then
        # If there is exactly one new schema, add it to the NEW_SCHEMA_FILEPATHS list
        if [ -n "$NEW_SCHEMAS_IN_SUBDIR" ]; then
            NEW_SCHEMA_FILEPATHS+=("$NEW_SCHEMAS_IN_SUBDIR")
            echo "Found new schema: $NEW_SCHEMAS_IN_SUBDIR and added it to the list."
        fi
    elif [ "$NUM_NEW_SCHEMAS" -gt 1 ]; then
        # If there is more than one new schema, add the subdirectory to the ERROR_DIRECTORIES list
        ERROR_DIRECTORIES+=("$subdir")
        echo "Found multiple new schemas in subdirectory: $subdir. Added to the error list."
    fi
done

# List the new schema filepaths
echo "NEW_SCHEMA_FILEPATHS:"
echo "${NEW_SCHEMA_FILEPATHS[@]}"

# List the error directories
echo "ERROR_DIRECTORIES:"
echo "${ERROR_DIRECTORIES[@]}"

# Write the lists to environment variable files
echo "NEW_SCHEMA_FILEPATHS=${NEW_SCHEMA_FILEPATHS[@]}" > /workspace/new_schema_filepaths.env
chmod 644 /workspace/new_schema_filepaths.env
echo "ERROR_DIRECTORIES=${ERROR_DIRECTORIES[@]}" > /workspace/error_directories.env
chmod 644 /workspace/error_directories.env

for new_schema_filepath in "${NEW_SCHEMA_FILEPATHS[@]}"; do
    echo "New schema: $new_schema_filepath"
done