#!/usr/bin/env bash

# Load the environment variables
source /workspace/new_schema_filepaths.env
source /workspace/error_directories.env
NEW_SCHEMA_PUBSUB_TOPIC=${_NEW_SCHEMA_PUBSUB_TOPIC}
SCHEMA_FAILURE_PUBSUB_TOPIC=${_SCHEMA_FAILURE_PUBSUB_TOPIC}


# Loop through new schemas
for new_schema_filepath in "${NEW_SCHEMA_FILEPATHS[@]}"; do
    # Send a Pub/Sub message with the schema file path
    gcloud pubsub topics publish schemas-for-publication --message ${new_schema_filepath}
done

# Loop through error directories
for error_directory in "${ERROR_DIRECTORIES[@]}"; do
    # Send a Pub/Sub message with the error directory
    gcloud pubsub topics publish fail-schema-topic --message ${error_directory}
done