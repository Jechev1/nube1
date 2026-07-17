import os
import time

import boto3


dynamodb = boto3.resource("dynamodb")
products_table = dynamodb.Table(os.environ["PRODUCTS_TABLE"])
audit_table = dynamodb.Table(os.environ["AUDIT_TABLE"])


def handler(event, context):
    detail = event.get("detail") or {}
    order_id = detail.get("order_id")
    items = detail.get("items") or []
    if not order_id or not items:
        raise ValueError("ordercreated requiere order_id e items")

    now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    for item in items:
        product_id = item.get("product_id")
        quantity = item.get("quantity")
        if not product_id or not isinstance(quantity, int) or quantity < 1:
            raise ValueError("cada item requiere product_id y quantity positivo")
        products_table.update_item(
            Key={"product_id": product_id},
            UpdateExpression="set stock = stock - :quantity, updated_at = :updated_at",
            ConditionExpression="attribute_exists(product_id) and stock >= :quantity",
            ExpressionAttributeValues={
                ":quantity": quantity,
                ":updated_at": now,
            },
        )

    audit_table.put_item(
        Item={
            "audit_id": f"{event.get('id', order_id)}#modificar_inventario",
            "event_id": event.get("id", order_id),
            "tipo_evento": "ordercreated",
            "usuario": detail.get("user_id", "system"),
            "accion": "modificar_inventario",
            "fecha": now,
            "resultado": "exitoso",
            "order_id": order_id,
        }
    )

    return {"processed": True, "order_id": order_id, "items_updated": len(items)}
