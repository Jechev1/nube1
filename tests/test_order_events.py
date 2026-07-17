import importlib.util
import os
import sys
import types
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EVENTS_PATH = ROOT / "modules" / "orders" / "lambda" / "events.py"


class FakeEventsClient:
    def __init__(self, response):
        self.response = response
        self.entries = []

    def put_events(self, Entries):
        self.entries.extend(Entries)
        return self.response


def load_events(response):
    client = FakeEventsClient(response)
    fake_boto3 = types.ModuleType("boto3")
    fake_boto3.client = lambda service: client
    fake_jsonutil = types.SimpleNamespace(dumps=lambda value: "serialized-detail")
    previous = {name: sys.modules.get(name) for name in ("boto3", "jsonutil")}
    sys.modules["boto3"] = fake_boto3
    sys.modules["jsonutil"] = fake_jsonutil
    os.environ["EVENT_BUS_NAME"] = "cloudshop-dev"
    try:
        spec = importlib.util.spec_from_file_location("events_under_test", EVENTS_PATH)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
    finally:
        for name, old_module in previous.items():
            if old_module is None:
                sys.modules.pop(name, None)
            else:
                sys.modules[name] = old_module
    return module, client


class OrderEventsTests(unittest.TestCase):
    def test_publish_uses_eventbridge_supported_fields(self):
        module, client = load_events({"FailedEntryCount": 0, "Entries": [{"EventId": "evt-1"}]})

        module.publish("OrderCreated", {"order_id": "order-1"})

        entry = client.entries[0]
        self.assertNotIn("Time", entry)
        self.assertEqual("cloudshop-dev", entry["EventBusName"])

    def test_publish_raises_when_eventbridge_rejects_entry(self):
        module, _ = load_events(
            {
                "FailedEntryCount": 1,
                "Entries": [{"ErrorCode": "InternalFailure", "ErrorMessage": "rejected"}],
            }
        )

        with self.assertRaisesRegex(RuntimeError, "InternalFailure"):
            module.publish("OrderCreated", {"order_id": "order-1"})


if __name__ == "__main__":
    unittest.main()
