import json
import os
import time
from decimal import Decimal

import boto3


dynamodb = boto3.resource("dynamodb")
audit_table = dynamodb.Table(os.environ["AUDIT_TABLE"])


def _action_for(event_type, detail):
    if event_type == "OrderCreated":
        return "crear_pedido"
    if event_type == "OrderStatusChanged":
        return (
            "cancelar_pedido"
            if detail.get("new_status") == "cancelled"
            else "actualizar_estado_pedido"
        )
    raise ValueError(f"tipo de evento no soportado: {event_type}")


def handler(event, context):
    event_id = event.get("id")
    event_type = event.get("detail-type")
    detail = json.loads(
        json.dumps(event.get("detail") or {}),
        parse_float=Decimal,
    )
    if not event_id or not event_type:
        raise ValueError("el evento requiere id y detail-type")

    action = _action_for(event_type, detail)
    audit = {
        "audit_id": f"{event_id}#{action}",
        "event_id": event_id,
        "tipo_evento": event_type.lower(),
        "usuario": detail.get("changed_by") or detail.get("user_id") or "system",
        "accion": action,
        "fecha": event.get("time") or time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "resultado": "exitoso",
        "order_id": detail.get("order_id", ""),
        "detalle": detail,
    }
    audit_table.put_item(Item=audit)

    return {"recorded": True, "audit_id": audit["audit_id"]}
