import json
import os
import urllib.request
import boto3

secrets = boto3.client("secretsmanager")


def get_api_key():

    response = secrets.get_secret_value(
        SecretId=os.environ["SECRET_ARN"]
    )

    secret = json.loads(
        response["SecretString"]
    )

    return secret["api_key"]


def call_api(method, endpoint, payload, api_key):

    data = json.dumps(payload).encode("utf-8")

    request = urllib.request.Request(
        endpoint,
        data=data,
        method=method,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
    )

    with urllib.request.urlopen(
        request,
        timeout=60
    ) as response:

        return response.read().decode("utf-8")


def lambda_handler(event, context):

    api_key = get_api_key()

    api_url = os.environ["COOKIE_API_URL"]

    applications = json.loads(
        os.environ["APPLICATIONS_JSON"]
    )

    results = []

    for name, application in applications.items():

        if not application.get("enabled", True):
            continue

        payload = {
            "application": name,
            "website_url": application["website_url"],
            "category": application["category"],
            "brand": application["brand"]
        }

        endpoint = f"{api_url}/publish"

        try:

            response = call_api(
                "POST",
                endpoint,
                payload,
                api_key
            )

            results.append({
                "application": name,
                "status": "published",
                "response": response
            })

        except Exception as error:

            results.append({
                "application": name,
                "status": "failed",
                "error": str(error)
            })

    return {
        "statusCode": 200,
        "results": results
    }