output "cloudfront_arn" {
  value = aws_cloudfront_distribution.frontend.arn
}
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.frontend.domain_name
}