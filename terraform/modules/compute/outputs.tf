output "nat_instance_id" {
  description = "The ID of the nat instance"
  value       = aws_instance.ecommerce_instance[5].id
}