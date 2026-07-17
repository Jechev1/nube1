import os
import boto3
import jsonutil

events_client = boto3.client("events")

_SOURCE = "cloudshop.orders"


def publish(detail_type: str, detail: dict) -> None:
    response = events_client.put_events(
        Entries=[
            {
                "Source": _SOURCE,
                "DetailType": detail_type,
                "Detail": jsonutil.dumps(detail),
                "EventBusName": os.environ["EVENT_BUS_NAME"],
            }
        ]
    )
    if response.get("FailedEntryCount", 0):
        failed = response.get("Entries", [{}])[0]
        code = failed.get("ErrorCode", "UnknownError")
        message = failed.get("ErrorMessage", "EventBridge rechazo el evento")
        raise RuntimeError(f"EventBridge {code}: {message}")
