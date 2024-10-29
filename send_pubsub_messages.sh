# Load the environment variables
source /workspace/new_schema_filepaths.env
source /workspace/error_directories.env
NEW_SCHEMA_PUBSUB_TOPIC=$_NEW_SCHEMA_PUBSUB_TOPIC
SCHEMA_FAILURE_PUBSUB_TOPIC=$_SCHEMA_FAILURE_PUBSUB_TOPIC

# Print the lists
echo "NEW_SCHEMA_FILEPATHS: ${NEW_SCHEMA_FILEPATHS[@]}"
echo "ERROR_DIRECTORIES: ${ERROR_DIRECTORIES[@]}"

# loop through new schemas
for NEW_SCHEMA_FILEPATH in "${NEW_SCHEMA_FILEPATHS[@]}"; do
    echo "Processing new schema: ${NEW_SCHEMA_FILEPATH}"
    # send a pubsub message with the schema file path
    gcloud pubsub topics publish $NEW_SCHEMA_PUBSUB_TOPIC --message ${NEW_SCHEMA_FILEPATH}
done

# loop through error directories
for ERROR_DIRECTORY in "${ERROR_DIRECTORIES[@]}"; do
    echo "Error: More than one new schema in directory: ${ERROR_DIRECTORY}"
    # send a pubsub message with the error directory
    gcloud pubsub topics publish $SCHEMA_FAILURE_PUBSUB_TOPIC --message ${ERROR_DIRECTORY}
done