output "public_subnet_id" {
  description = "The ID of the security group"
  value       = aws_subnet.public_subnet.id
}
output "private_subnet_id" {
  description = "The ID of the security group"
  value       = aws_subnet.private_subnet.id
}
output "sec_grp_ids" {
  description = "IDs of Security Groups"
  value = {
    "master" : aws_security_group.master_sec_group.id
    "workers" : aws_security_group.worker_sec_group.id
    "nat" : aws_security_group.nat_sec_group.id
    "prometheus" : aws_security_group.prom_sec_group.id
  }
}