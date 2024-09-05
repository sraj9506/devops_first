output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.security_group.id
}
output "subnet_id" {
  description = "The ID of the security group"
  value       = aws_subnet.subnet.id
}