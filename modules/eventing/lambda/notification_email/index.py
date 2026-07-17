import os

import boto3


ses_client = boto3.client("ses")


def handler(event, context):
    event_type = event.get("detail-type")
    detail = event.get("detail") or {}
    if event_type != "OrderCreated":
        raise ValueError(f"tipo de evento no soportado: {event_type}")

    recipient = detail.get("customer_email")
    order_id = detail.get("order_id")
    if not recipient or not order_id:
        raise ValueError("ordercreated requiere customer_email y order_id")

    item_count = sum(int(item.get("quantity", 0)) for item in detail.get("items", []))
    total = detail.get("total_amount", 0)
    subject = f"cloudshop: pedido {order_id} confirmado"
    body = (
        f"tu pedido {order_id} fue creado correctamente.\n\n"
        f"productos: {item_count}\n"
        f"total: {total}\n"
        "gracias por comprar en cloudshop."
    )
    response = ses_client.send_email(
        Source=os.environ["SES_FROM_EMAIL"],
        Destination={"ToAddresses": [recipient]},
        Message={
            "Subject": {"Data": subject, "Charset": "UTF-8"},
            "Body": {"Text": {"Data": body, "Charset": "UTF-8"}},
        },
    )
    return {"message_id": response["MessageId"], "order_id": order_id}
