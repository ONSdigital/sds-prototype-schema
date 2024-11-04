#!/usr/bin/env bash

# Load the environment variables
mapfile -t NEW_SCHEMA_FILEPATHS < /workspace/new_schema_filepaths.env
NEW_SCHEMA_FILEPATHS=("${NEW_SCHEMA_FILEPATHS[@]}")
# source /workspace/error_directories.env
NEW_SCHEMA_PUBSUB_TOPIC=${_NEW_SCHEMA_PUBSUB_TOPIC}
SCHEMA_FAILURE_PUBSUB_TOPIC=${_SCHEMA_FAILURE_PUBSUB_TOPIC}

# if there are no new schemas, skip
if [ ${#NEW_SCHEMA_FILEPATHS[@]} -eq 0 ]; then
    echo "Not sending any Pub/Sub messages."
    exit 0
fi

for schema in "${NEW_SCHEMA_FILEPATHS[@]}"; do
    echo "New schema: $schema"
done

# Loop through new schemas
for new_schema_filepath in "${NEW_SCHEMA_FILEPATHS[@]}"; do
    # Send a Pub/Sub message with the schema file path
    gcloud pubsub topics publish schemas-for-publication --message ${new_schema_filepath}
done
