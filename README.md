## Evidencias de los casos de prueba

### Caso 1 – Intento de acceso sin permisos (403 Forbidden)

Se realizó una petición `GET /v1/products` con la API Key correcta pero **sin el token JWT de Cognito**. El API Gateway respondió con `403 Forbidden`, demostrando que la autenticación está correctamente configurada.

![Caso 1 - 403 Forbidden](evidencias/C1.png)

---

### Caso 4 – Despliegue completo mediante Terraform

Se ejecutó `terraform apply` desde cero, creando todos los recursos definidos en el código (S3, CloudFront, WAF, API Gateway, IAM, Cognito). Terraform completó el despliegue exitosamente.`

![Caso 4 - Terraform Apply](evidencias/C4.png)