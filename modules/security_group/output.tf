output "app_sg_id" {
  value = aws_security_group.app_sg.id
}

output "opmng_sg_id" {
  value = aws_security_group.opmng_sg.id
}

output "db_sg_id" {
  value = aws_security_group.db_sg.id
}
