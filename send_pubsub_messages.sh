#!/usr/bin/env bash

# Load the environment variables
source /workspace/new_schema_filepaths.env
source /workspace/error_directories.env
NEW_SCHEMA_PUBSUB_TOPIC=${_NEW_SCHEMA_PUBSUB_TOPIC}  # Changed to use curly braces
SCHEMA_FAILURE_PUBSUB_TOPIC=${_SCHEMA_FAILURE_PUBSUB_TOPIC}  # Changed to use curly braces
NEW_SCHEMA_FILEPATH=""
ERROR_DIRECTORY=""


# Loop through new schemas
for NEW_SCHEMA_FILEPATH in "${NEW_SCHEMA_FILEPATHS[@]}"; do
    # Send a Pub/Sub message with the schema file path
    gcloud pubsub topics publish ${NEW_SCHEMA_PUBSUB_TOPIC} --message ("$NEW_SCHEMA_FILEPATH")

# Loop through error directories
for ERROR_DIRECTORY in "${ERROR_DIRECTORIES[@]}"; do
    # Send a Pub/Sub message with the error directory
    gcloud pubsub topics publish ${SCHEMA_FAILURE_PUBSUB_TOPIC} --message ("$ERROR_DIRECTORY")