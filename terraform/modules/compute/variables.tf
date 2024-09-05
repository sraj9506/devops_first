variable "security_group_id" {
  description = "The ID of the security group"
  type        = string
}
variable "subnet_id" {
  description = "The ID of the subnet"
  type        = string
}
variable "bucket_arn" {
  description = "Bucket ARN"
  type = string
}
variable "instance_prefix" {
  description = "Prefix of instances"
  type = list(string)
  default = [ "master","worker_1","worker_2" ]
}
variable "base_name" {
  description = "Base name of resources"
  type        = string
}
