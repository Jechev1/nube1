import os
import boto3

dynamodb = boto3.resource("dynamodb")

stores_table = dynamodb.Table(os.environ["STORES_TABLE"])
products_table = dynamodb.Table(os.environ["PRODUCTS_TABLE"])
cart_table = dynamodb.Table(os.environ["CART_TABLE"])
