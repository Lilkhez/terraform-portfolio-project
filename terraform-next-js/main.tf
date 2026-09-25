provider "aws" {
  region = "ap-southeast-2"
}


# S3 bucket that hosts the website
resource "aws_s3_bucket" "my_nextjs_website" {
  bucket = "my-tf-nextjs-sep-aa"

  tags = {
    Name = "Portfolio Website"
    Environment = "Production"
  }

}

# Bucket Ownership
resource "aws_s3_bucket_ownership_controls" "my_nextjs_website_ownership_controls" {
  bucket = aws_s3_bucket.my_nextjs_website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  
}

# Enable website hosting
# index.html for homepage and 404.html for missing pages
resource "aws_s3_bucket_website_configuration" "my_nextjs_website" {
    bucket = aws_s3_bucket.my_nextjs_website.id

    index_document {
      suffix = "index.html"
    }

    error_document {
      key = "404.html"
    }  
}

# Turn on public access permission
resource "aws_s3_bucket_public_access_block" "my_nextjs_website" {
  bucket = aws_s3_bucket.my_nextjs_website.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "my_nextjs_website_acl" {
  depends_on = [ aws_s3_bucket_ownership_controls.my_nextjs_website_ownership_controls ]

  bucket = aws_s3_bucket.my_nextjs_website.id
  acl = "public-read"
}


# s3 bucket policy
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.my_nextjs_website.id

  policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
          {
              Effect = "Allow"
              Principal = "*"
              Action = "s3:GetObject"
              Resource = "${aws_s3_bucket.my_nextjs_website.arn}/*"
          }
      ]
  }
  )
  
  depends_on = [ aws_s3_bucket_public_access_block.my_nextjs_website ]
}



# Origin Access Identity (OAI)
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "OAI for Nextjs Portfolio Website"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "my_nextjs_website_distribution" {
    origin {
      domain_name = aws_s3_bucket.my_nextjs_website.bucket_regional_domain_name
      origin_id = "my_nextjs_website"

      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
      }

  }

  enabled = true
  is_ipv6_enabled = true
  comment = "Nextjs Portfolio Website"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "my_nextjs_website"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  tags = {
    Name = "Cloudfront Distribution"
    Environment = "Production"
  }
}