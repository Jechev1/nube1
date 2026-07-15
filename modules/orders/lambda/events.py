import os
import time
import boto3
import jsonutil

events_client = boto3.client("events")

_SOURCE = "cloudshop.orders"


def publish(detail_type: str, detail: dict) -> None:
    events_client.put_events(
        Entries=[
            {
                "Source": _SOURCE,
                "DetailType": detail_type,
                "Detail": jsonutil.dumps(detail),
                "EventBusName": os.environ["EVENT_BUS_NAME"],
                "Time": time.time(),
            }
        ]
    )
