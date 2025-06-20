output "app_jar_bucket" {
  value = aws_s3_bucket.app_jar_bucket.id
}

output "app_jar_key" {
  value = aws_s3_bucket_object.app_jar.key
}
