import logging
import sys
import google.auth.transport.requests
from google.oauth2 import service_account
import os
import requests
import subprocess
import json
import random
 
def publish_schema_to_sds(schema, survey_id):
    """
    Function to publish schema to SDS
 
    Parameters:
        schema(dict): A dict of the schema being published that matches the agreed schema structure
        survey_id(str): The survey id of the schema
 
    Returns:
        HTTP Response, includes status code and message. Refer to openapi.yaml for detail
    """
 
    # Service account key, that has been granted required roles to connect SDS service
    service_account_key = os.environ["GOOGLE_APPLICATION_CREDENTIALS"]

    # The URL to access the load balancer on SDS project.
    base_url = os.environ["SANDBOX_LOAD_BALANCER_URL"]

    # The SDS project ID
    project_id = os.environ["SDS_PROJECT_ID"]

    try:
        # Obtain the Client ID of OAuth Client on SDS project. Require the SDS Project ID, request it from SDS team
        audience = _get_client_id(project_id, service_account_key)
        # Make request to IAP of SDS load balancer
        response = _make_iap_request(f"{base_url}/v1/schema?survey_id={survey_id}", audience, service_account_key, schema)
        return response
    except Exception as e:
        print(e)
        return {
            "status_code": 500,
            "message": "Internal Server Error"
        }
 
 
def _get_client_id(project_id, service_account_key) -> str:
    """
    Function to get Client ID of OAuth Client on SDS project    
    Require the role OAuth Config Editor & Compute Viewer for the service account used
 
    Parameters:
        project_id(str): The SDS Project ID
        service_account_key(str): The Json key file of the service account
 
    Returns:
        OAuth Client ID
    """
 
    try:
        # Fetch for the client ID of OAuth Client on SDS
        cmd_get_oauth_brand_name = "gcloud iap oauth-brands list --format='value(name)' --limit=1 --project=" + project_id
        oauth_brand_name = subprocess.check_output(cmd_get_oauth_brand_name, shell=True)
        oauth_brand_name = oauth_brand_name.decode().strip()
        cmd_get_oauth_client_name = "gcloud iap oauth-clients list " + oauth_brand_name + " --format='value(name)' --limit=1"
        oauth_client_name = subprocess.check_output(cmd_get_oauth_client_name, shell=True)
        oauth_client_name = oauth_client_name.decode().strip()
        oauth_client_id = oauth_client_name[oauth_client_name.rfind('/')+1:]
        return oauth_client_id
    except subprocess.CalledProcessError as e:
        print(e.output)
        #Raise exception
 
 
def _generate_headers(audience, service_account_key) -> dict[str, str]:
    """
    Function to create headers for authentication with auth token.
 
    Parameters:
        audience(str): The Client ID of the OAuth client on SDS project
        service_account_key(str): The Json key file of the service account
 
    Returns:
        dict[str, str]: the headers required for remote authentication.
    """
     
    headers = {}
 
    auth_req = google.auth.transport.requests.Request()
    # convert the key file to a dict
    service_account_key = json.loads(service_account_key)
    credentials = service_account.IDTokenCredentials.from_service_account_info(service_account_key, target_audience=audience)
    credentials.refresh(auth_req)
    auth_token = credentials.token
 
    headers = {
        "Authorization": f"Bearer {auth_token}",
        "Content-Type": "application/json",
    }
 
    return headers
 
 
def _make_iap_request(req_url, audience, service_account_key, data):
    """
    Function to make IAP request to SDS
 
    Parameters:
        req_url(str): The full path of the SDS endpoint
        audience(str): The Client ID of the OAuth client on SDS project
        service_account_key(str): The Json key file of the service account
        data(schema): The schema being published
 
    Returns:
        HTTP Response, includes status code and message. Refer to openapi.yaml for detail
    """
    # Set Headers
 
    headers = _generate_headers(audience, service_account_key)
 
    try:
        response = requests.request(
            'POST',
            req_url,
            headers=headers,
            json=data
        )
        response.raise_for_status()
        return response
    except requests.exceptions.HTTPError as error:
        logging.error("HTTP error occurred: %s", error)
        return response
    
def _retrieve_schema_file() -> dict:
    """
    Function to retrieve the changed file contents as JSON
 
    Returns:
        dict: The schema being published
    """
    try:
        with open(sys.argv[1], "r") as file:
            schema = json.load(file)
            return schema
    except:
        print("Error reading json file - ")
        sys.exit(1)

if __name__ == "__main__":

    # for now - use a list of survey_ids and pick one at random - this implementation will change
    survey_ids = ["041", "132", "133", "156", "141", "221", "241", "068", "071", "066", "076"]
    survey_id = random.choice(survey_ids)

    # Retrieve the schema file
    schema = _retrieve_schema_file()

    # Publish the schema to SDS
    response = publish_schema_to_sds(schema, survey_id)

    print(response.status_code)
    print("Survey ID: " + survey_id)
