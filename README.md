## Caso 1 – Intento de acceso sin permisos

**Objetivo**: Verificar que el API Gateway rechaza peticiones sin autenticación.

**Pasos**:
1. Hacer una petición GET a `/v1/products` con la API Key correcta.
2. No incluir el token JWT de Cognito.

**Resultado esperado**: 403 Forbidden.

**Resultado obtenido**: 403 Forbidden con mensaje `{"message":"Forbidden"}`.

**Evidencia**: [captura de pantalla]