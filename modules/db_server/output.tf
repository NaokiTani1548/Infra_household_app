output "db_private_ip" {
  value = aws_instance.ondemand-db.private_ip
}

output "mysql_username" {
  value = "admin" 
}

output "mysql_password" {
  value = "Hitandrun48."
}

output "key_pair" {
  value = aws_key_pair.keypair.id
}