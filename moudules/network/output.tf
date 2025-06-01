output "VPCID" {
  value = aws_vpc.vpc.id
}

output "public1CID" {
  value = aws_subnet.public_subnet_1c.id
}

output "public1DID" {
  value = aws_subnet.public_subnet_1d.id
}

output "private1CID" {
  value = aws_subnet.private_subnet_1c.id
}

output "private2CID" {
  value = aws_subnet.private_subnet_1d.id
}
