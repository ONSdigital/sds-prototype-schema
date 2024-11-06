#!/usr/bin/env bash

# Load the environment variables
NEW_SCHEMA_PUBSUB_TOPIC=${_NEW_SCHEMA_PUBSUB_TOPIC}
SCHEMA_FAILURE_PUBSUB_TOPIC=${_SCHEMA_FAILURE_PUBSUB_TOPIC}

# check file exists
if [ -f /workspace/new_schema_filepaths.env ]; then

    mapfile -t NEW_SCHEMA_FILEPATHS < /workspace/new_schema_filepaths.env
    NEW_SCHEMA_FILEPATHS=("${NEW_SCHEMA_FILEPATHS[@]}")

    # Loop through new schemas - ensuring that the filepath is not empty
    for new_schema_filepath in "${NEW_SCHEMA_FILEPATHS[@]}"; do
        if [ -n "$new_schema_filepath" ]; then
            echo "Sending message for: $new_schema_filepath"
            # Send a Pub/Sub message with the schema file path
            gcloud pubsub topics publish schemas-for-publication --message ${new_schema_filepath}
        fi
    done
else
    echo "No new schema filepaths found. Not sending any Pub/Sub messages."
fi

if [ -f /workspace/error_directories.env ]; then
    mapfile -t ERROR_DIRECTORIES < /workspace/error_directories.env
    ERROR_DIRECTORIES=("${ERROR_DIRECTORIES[@]}")

    # Loop through error directories - ensuring that the directory is not empty
    for error_directory in "${ERROR_DIRECTORIES[@]}"; do
        if [ -n "$error_directory" ]; then
            echo "Sending error message for: $error_directory"
            # Send a Pub/Sub message with the error directory
            gcloud pubsub topics publish fail-schema-topic --message ${error_directory}
        fi
    done
else
    echo "No error directories found. Not sending any Pub/Sub messages."
fi
