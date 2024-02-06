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
 
    # Service account key file, that has been granted required roles to connect SDS service
    key_file = os.environ["GCP_SA_KEY"]
    key_dict = json.loads(key_file)
    key_file = key_dict
 
    # Obtain the Client ID of OAuth Client on SDS project. Require the SDS Project ID, request it from SDS team
    project_id = "ons-sds-jamesb-sandbox"
    audience = _get_client_id(project_id, key_file)
     
    # The URL to access the load balancer on SDS project. Request it from SDS team
    base_url = "https://35.190.114.159.nip.io"
 
    # Make request to IAP of SDS load balancer
    response = _make_iap_request(f"{base_url}/v1/schema?survey_id={survey_id}", audience, key_file, schema)

    return response
 
 
def _get_client_id(project_id, key_file) -> str:
    """
    Function to get Client ID of OAuth Client on SDS project    
    Require the role OAuth Config Editor & Compute Viewer for the service account used
 
    Parameters:
        project_id(str): The SDS Project ID
        key_file(str): The Json key file of the service account
 
    Returns:
        OAuth Client ID
    """
 
    try:
        # Set to use the supplied SA as the default configuration to connect gcloud
        cmd_auth = "gcloud auth activate-service-account --key-file=" + key_file
        subprocess.run(cmd_auth, shell=True)
        # Fetch for the client ID of OAuth Client on SDS
        cmd_get_oauth_brand_name = "gcloud iap oauth-brands list --format='value(name)' --limit=1 --project=" + project_id
        oauth_brand_name = subprocess.check_output(cmd_get_oauth_brand_name, shell=True)
        oauth_brand_name = oauth_brand_name.decode().strip()
        cmd_get_oauth_client_name = "gcloud iap oauth-clients list " + oauth_brand_name + " --format='value(name)' --limit=1"
        oauth_client_name = subprocess.check_output(cmd_get_oauth_client_name, shell=True)
        oauth_client_name = oauth_client_name.decode().strip()
        oauth_client_id = oauth_client_name[oauth_client_name.rfind('/')+1:]
        # Resume to use original SA stored in GOOGLE_APPLICATION_CREDENTIALS. Uncomment the two lines below if needed
        # cmd_resume_auth = "gcloud auth activate-service-account --key-file=" + os.environ["GOOGLE_APPLICATION_CREDENTIALS"]
        # subprocess.run(cmd_resume_auth, shell=True)
        return oauth_client_id
    except subprocess.CalledProcessError as e:
        print(e.output)
        #Raise exception
 
 
def _generate_headers(audience, key_file) -> dict[str, str]:
    """
    Function to create headers for authentication with auth token.
 
    Parameters:
        audience(str): The Client ID of the OAuth client on SDS project
        key_file(str): The Json key file of the service account
 
    Returns:
        dict[str, str]: the headers required for remote authentication.
    """
     
    headers = {}
 
    auth_req = google.auth.transport.requests.Request()
    credentials = service_account.IDTokenCredentials.from_service_account_file(key_file, target_audience=audience)
    credentials.refresh(auth_req)
    auth_token = credentials.token
 
    headers = {
        "Authorization": f"Bearer {auth_token}",
        "Content-Type": "application/json",
    }
 
    return headers
 
 
def _make_iap_request(req_url, audience, key_file, data):
    """
    Function to make IAP request to SDS
 
    Parameters:
        req_url(str): The full path of the SDS endpoint
        audience(str): The Client ID of the OAuth client on SDS project
        key_file(str): The Json key file of the service account
        data(schema): The schema being published
 
    Returns:
        HTTP Response, includes status code and message. Refer to openapi.yaml for detail
    """
    # Set Headers
 
    headers = _generate_headers(audience, key_file)
 
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
    