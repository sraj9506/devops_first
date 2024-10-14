variable "base_name" {
  description = "Base name of resources"
  type        = string
  default = "ecommerce"
}
variable "vault_address" {
  description = "Address of vault"
  type = string
}
variable "vault_token" {
  description = "Token for vault"
  type = string
}
variable "pub_path" {
 description = "Path of public key" 
 type = string
  default = "~/.ssh/id_rsa.pub"
}