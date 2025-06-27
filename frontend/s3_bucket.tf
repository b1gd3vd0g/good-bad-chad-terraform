# Create the S3 bucket.
resource "aws_s3_bucket" "bucket" {
  bucket        = var.domain_name
  force_destroy = true
}

# Allow public access to the S3 bucket.
resource "aws_s3_bucket_public_access_block" "bucket_access" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Configure the S3 bucket to serve a static website. 
resource "aws_s3_bucket_website_configuration" "bucket_website" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = local.entry_point
  }

  error_document {
    key = local.entry_point
  }
}

# Give read access for the S3 bucket to anybody.
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.bucket.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.bucket_access]
}
