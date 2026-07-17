import importlib.util
import os
import sys
import types
import unittest
from decimal import Decimal
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EVENTING_ROOT = ROOT / "modules" / "eventing" / "lambda"


class FakeTable:
    def __init__(self, existing=None):
        self.existing = existing
        self.put_calls = []
        self.update_calls = []

    def get_item(self, **_kwargs):
        return {"Item": self.existing} if self.existing else {}

    def put_item(self, **kwargs):
        self.put_calls.append(kwargs)

    def update_item(self, **kwargs):
        self.update_calls.append(kwargs)


class FakeDynamoResource:
    def __init__(self, tables):
        self.tables = tables

    def Table(self, name):
        return self.tables[name]


class FakeSesClient:
    def __init__(self):
        self.calls = []

    def send_email(self, **kwargs):
        self.calls.append(kwargs)
        return {"MessageId": "message-1"}


def load_handler(relative_path, clients, tables=None):
    path = EVENTING_ROOT / relative_path / "index.py"
    if not path.exists():
        raise AssertionError(f"Falta el handler P5: {path.relative_to(ROOT)}")

    fake_boto3 = types.ModuleType("boto3")
    fake_boto3.client = lambda service: clients[service]
    fake_boto3.resource = lambda service: FakeDynamoResource(tables or {})
    previous = sys.modules.get("boto3")
    sys.modules["boto3"] = fake_boto3
    try:
        spec = importlib.util.spec_from_file_location(f"{relative_path}_under_test", path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
    finally:
        if previous is None:
            sys.modules.pop("boto3", None)
        else:
            sys.modules["boto3"] = previous
    return module


class EventingHandlersTests(unittest.TestCase):
    def setUp(self):
        os.environ.update(
            {
                "PRODUCTS_TABLE": "products",
                "AUDIT_TABLE": "audit",
                "SES_FROM_EMAIL": "orders@cloudshop.example",
            }
        )

    def test_update_inventory_decrements_every_item(self):
        products = FakeTable()
        audit = FakeTable()
        module = load_handler(
            "update_inventory",
            {},
            {"products": products, "audit": audit},
        )
        event = {
            "id": "event-1",
            "detail-type": "OrderCreated",
            "detail": {
                "order_id": "order-1",
                "user_id": "customer-1",
                "customer_email": "customer@example.com",
                "total_amount": 50,
                "items": [
                    {"product_id": "product-1", "quantity": 2},
                    {"product_id": "product-2", "quantity": 1},
                ],
            },
        }

        response = module.handler(event, None)

        self.assertTrue(response["processed"])
        self.assertEqual(2, len(products.update_calls))
        self.assertEqual(
            {"product-1", "product-2"},
            {call["Key"]["product_id"] for call in products.update_calls},
        )
        self.assertTrue(
            all("stock >= :quantity" in call["ConditionExpression"] for call in products.update_calls)
        )
        self.assertEqual(1, len(audit.put_calls))
        self.assertEqual("modificar_inventario", audit.put_calls[0]["Item"]["accion"])
        self.assertEqual("exitoso", audit.put_calls[0]["Item"]["resultado"])

    def test_audit_logger_records_order_creation(self):
        audit_table = FakeTable()
        module = load_handler("audit_logger", {}, {"audit": audit_table})

        module.handler(
            {
                "id": "event-order",
                "time": "2026-07-17T10:00:00Z",
                "detail-type": "OrderCreated",
                "detail": {"order_id": "order-1", "user_id": "customer-1"},
            },
            None,
        )

        actions = [call["Item"]["accion"] for call in audit_table.put_calls]
        self.assertEqual(["crear_pedido"], actions)
        self.assertTrue(all(call["Item"]["resultado"] == "exitoso" for call in audit_table.put_calls))

    def test_audit_logger_normalizes_fractional_amounts_for_dynamodb(self):
        audit_table = FakeTable()
        module = load_handler("audit_logger", {}, {"audit": audit_table})
        event = {
            "id": "event-decimal",
            "detail-type": "OrderCreated",
            "detail": {
                "order_id": "order-1",
                "user_id": "customer-1",
                "total_amount": 50.25,
            },
        }

        module.handler(event, None)

        stored_total = audit_table.put_calls[0]["Item"]["detalle"]["total_amount"]
        self.assertEqual(Decimal("50.25"), stored_total)
        self.assertIsInstance(stored_total, Decimal)

    def test_audit_logger_records_order_cancellation(self):
        audit_table = FakeTable()
        module = load_handler("audit_logger", {}, {"audit": audit_table})
        module.handler(
            {
                "id": "event-cancel",
                "detail-type": "OrderStatusChanged",
                "detail": {
                    "order_id": "order-1",
                    "user_id": "customer-1",
                    "changed_by": "operator-1",
                    "new_status": "cancelled",
                },
            },
            None,
        )

        item = audit_table.put_calls[0]["Item"]
        self.assertEqual("cancelar_pedido", item["accion"])
        self.assertEqual("operator-1", item["usuario"])

    def test_notification_email_sends_order_confirmation(self):
        ses_client = FakeSesClient()
        module = load_handler("notification_email", {"ses": ses_client})
        event = {
            "id": "event-2",
            "detail-type": "OrderCreated",
            "detail": {
                "order_id": "order-1",
                "user_id": "customer-1",
                "customer_email": "customer@example.com",
                "total_amount": 50,
                "items": [{"product_id": "product-1", "quantity": 2}],
            },
        }

        response = module.handler(event, None)

        self.assertEqual("message-1", response["message_id"])
        call = ses_client.calls[0]
        self.assertEqual("orders@cloudshop.example", call["Source"])
        self.assertEqual(["customer@example.com"], call["Destination"]["ToAddresses"])
        self.assertIn("order-1", call["Message"]["Subject"]["Data"])


if __name__ == "__main__":
    unittest.main()
