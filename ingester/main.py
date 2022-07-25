import os
from typing import Dict, Any

import influxdb_client
from influxdb_client.client.write_api import SYNCHRONOUS
import boto3
from aws_lambda_powertools import Tracer, Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

session = boto3.Session()
ssm = session.client('ssm')
api_token = \
    ssm.get_parameter(Name=os.environ["INFLUXDB_API_TOKEN_SSM_PARAMETER_NAME"], WithDecryption=True)['Parameter'][
        'Value']
client = influxdb_client.InfluxDBClient(
    url=os.environ["INFLUXDB_URL"],
    token=api_token,
    org="influxdata"
)
write_api = client.write_api(write_options=SYNCHRONOUS)

tracer = Tracer()
logger = Logger()


@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=True)
def handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    print(event)
    e = validate_and_parse_event(event)
    p = influxdb_client.Point("home_measurement").tag("location", "Prague").field("temperature", e["temperature"])
    write_api.write(bucket="default", org="influxdata", record=p)
    return {"message": "Hello, World!"}


def validate_and_parse_event(event):
    for required_key in ["t"]:
        if required_key not in event:
            raise Exception('Invalid event, missing key: {}'.format(required_key))
    return {
        "temperature": event["t"],
    }
