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
