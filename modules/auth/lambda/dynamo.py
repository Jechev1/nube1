import os
import boto3

dynamodb = boto3.resource("dynamodb")
table_name = os.environ["USERS_TABLE"]
table = dynamodb.Table(table_name)


def get_user_by_id(user_id: str) -> dict | None:
    resp = table.get_item(Key={"user_id": user_id})
    return resp.get("Item")


def get_user_by_email(email: str) -> dict | None:
    resp = table.query(
        IndexName="email-index",
        KeyConditionExpression="email = :e",
        ExpressionAttributeValues={":e": email},
        Limit=1,
    )
    items = resp.get("Items", [])
    return items[0] if items else None


def create_user(user: dict) -> None:
    table.put_item(Item=user)


def update_refresh_token(user_id: str, refresh_token: str) -> None:
    table.update_item(
        Key={"user_id": user_id},
        UpdateExpression="SET refresh_token = :rt",
        ExpressionAttributeValues={":rt": refresh_token},
    )
