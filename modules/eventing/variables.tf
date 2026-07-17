variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "products_table_name" {
  type        = string
  description = "nombre de la tabla products"
}

variable "products_table_arn" {
  type        = string
  description = "arn de la tabla products"
}

variable "ses_sender_email" {
  type        = string
  description = "correo que ses usa para mandar las notificaciones"

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.ses_sender_email))
    error_message = "ses_sender_email debe ser un correo valido."
  }
}
