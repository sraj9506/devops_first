variable "security_group_ids" {
  description = "The ID of the security groups"
  type        = list(string)
}
variable "public_subnet_id" {
  description = "The ID of the subnet"
  type        = string
}
variable "private_subnet_id" {
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
  default = ["webserver_1","webserver_2","appserver","dbserver","kubemaster","prometheus","nat"]
}
variable "base_name" {
  description = "Base name of resources"
  type        = string
}
variable "pub_path" {
  description = "Path of the public key"
  type = string
}
variable "key_prefix" {
  description = "Prefix of key value pair"
  type = string
}