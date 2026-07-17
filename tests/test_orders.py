import importlib.util
import json
import sys
import types
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ORDERS_PATH = ROOT / "modules" / "orders" / "lambda" / "orders.py"


class FakeOrdersTable:
    def __init__(self, order=None):
        self.order = order
        self.put_items = []
        self.update_calls = []

    def get_item(self, **_kwargs):
        return {"Item": self.order} if self.order else {}

    def put_item(self, **kwargs):
        self.put_items.append(kwargs["Item"])

    def update_item(self, **kwargs):
        self.update_calls.append(kwargs)


class FakeCartTable:
    def __init__(self, items):
        self.items = items
        self.deleted = []

    def query(self, **_kwargs):
        return {"Items": self.items}

    def delete_item(self, **kwargs):
        self.deleted.append(kwargs["Key"])


class FakeProductsTable:
    def __init__(self, products):
        self.products = products

    def get_item(self, Key):
        product = self.products.get(Key["product_id"])
        return {"Item": product} if product else {}


class FakeEvents:
    def __init__(self):
        self.published = []

    def publish(self, detail_type, detail):
        self.published.append((detail_type, detail))


def load_orders(*, order=None, cart_items=None, products=None):
    fake_dynamo = types.SimpleNamespace(
        orders_table=FakeOrdersTable(order),
        cart_table=FakeCartTable(cart_items or []),
        products_table=FakeProductsTable(products or {}),
    )
    fake_events = FakeEvents()
    fake_jsonutil = types.SimpleNamespace(
        parse_body=lambda event: json.loads(event["body"]),
        dumps=lambda data: json.dumps(data, default=str),
    )
    fake_conditions = types.ModuleType("boto3.dynamodb.conditions")
    fake_conditions.Key = lambda name: types.SimpleNamespace(eq=lambda value: (name, value))

    replacements = {
        "dynamo": fake_dynamo,
        "events": fake_events,
        "jsonutil": fake_jsonutil,
        "boto3.dynamodb.conditions": fake_conditions,
    }
    previous = {name: sys.modules.get(name) for name in replacements}
    sys.modules.update(replacements)
    try:
        spec = importlib.util.spec_from_file_location("orders_under_test", ORDERS_PATH)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
    finally:
        for name, old_module in previous.items():
            if old_module is None:
                sys.modules.pop(name, None)
            else:
                sys.modules[name] = old_module
    return module, fake_dynamo, fake_events


class OrdersTests(unittest.TestCase):
    def test_confirmed_order_can_move_to_preparing(self):
        module, fake_dynamo, _ = load_orders(
            order={"order_id": "order-1", "user_id": "customer-1", "status": "confirmed"}
        )
        event = {
            "_auth": {"user_id": "operator-1", "role": "operator"},
            "pathParameters": {"id": "order-1"},
            "body": json.dumps({"status": "preparing"}),
        }

        response = module.update_status(event)

        self.assertEqual(200, response["statusCode"])
        self.assertEqual(
            "preparing",
            fake_dynamo.orders_table.update_calls[0]["ExpressionAttributeValues"][":s"],
        )

    def test_order_created_event_contains_customer_email(self):
        module, _, fake_events = load_orders(
            cart_items=[{"product_id": "product-1", "quantity": 2}],
            products={
                "product-1": {
                    "product_id": "product-1",
                    "store_id": "store-1",
                    "name": "Keyboard",
                    "price": 25,
                    "stock": 5,
                }
            },
        )
        event = {
            "_auth": {
                "user_id": "customer-1",
                "role": "customer",
                "email": "customer@example.com",
            }
        }

        response = module.create_order(event)

        self.assertEqual(201, response["statusCode"])
        detail_type, detail = fake_events.published[0]
        self.assertEqual("OrderCreated", detail_type)
        self.assertEqual("customer@example.com", detail.get("customer_email"))


if __name__ == "__main__":
    unittest.main()
