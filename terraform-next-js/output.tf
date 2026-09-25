output "bucket_website_endpoint" {
  value = aws_s3_bucket_website_configuration.my_nextjs_website.website_endpoint
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.my_nextjs_website_distribution.domain_name
}
