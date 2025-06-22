resource "aws_s3_bucket" "app_jar_bucket" {
  bucket = "${var.project}-${var.env}-jar-bucket"

  tags = {
    Name        = "${var.project}-${var.env}-app-jar-bucket"
    Environment = var.env
    Project     = var.project
  }

  force_destroy = true  # バケット削除時に中身も削除（開発環境用）
}

resource "aws_s3_bucket_object" "app_jar" {  # aws_s3_object から aws_s3_bucket_object に変更
  bucket = aws_s3_bucket.app_jar_bucket.id
  key    = "builds/app.jar"
  source = var.jar_local_path
  etag   = filemd5(var.jar_local_path)
  content_type = "application/java-archive"
}


resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_name
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "index.html"
  }

  tags = {
    Name = "frontend-static-hosting"
  }
}

resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}