import json
from middleware import require_role, AuthError
import auth_service


def handler(event, context):
    method = event.get("httpMethod", "")
    path = event.get("path", "")

    path_part = path.rstrip("/").split("/")[-1] if path.rstrip("/") else ""

    routes = {
        ("POST", "register"): _public_register,
        ("POST", "login"): _public_login,
        ("POST", "refresh"): _public_refresh,
        ("GET", "profile"): _protected_profile,
        ("POST", "logout"): _protected_logout,
    }

    route_key = (method, path_part)
    route = routes.get(route_key)
    if route:
        return route(event, context)

    return {
        "statusCode": 404,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": "Endpoint no encontrado"}),
    }


def _parse_body(event: dict) -> dict:
    body = event.get("body")
    if body and isinstance(body, str):
        try:
            return json.loads(body)
        except json.JSONDecodeError:
            return {}
    return body if isinstance(body, dict) else {}


def _public_register(event, context=None):
    body = _parse_body(event)
    return auth_service.register(body)


def _public_login(event, context=None):
    body = _parse_body(event)
    return auth_service.login(body)


def _public_refresh(event, context=None):
    body = _parse_body(event)
    return auth_service.refresh(body)


@require_role("admin", "operator", "customer")
def _protected_profile(event, context=None):
    return auth_service.profile(event)


@require_role("admin", "operator", "customer")
def _protected_logout(event, context=None):
    return auth_service.logout(event)
