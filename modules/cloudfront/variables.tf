variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "bucket_name" {
  type = string
}
variable "s3_website_endpoint" {
  type = string
}
variable "web_acl_id" {
  description = "ARN del Web ACL de WAF para asociar a CloudFront"
  type        = string
  default     = null
}