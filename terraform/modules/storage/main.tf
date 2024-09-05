resource "aws_s3_bucket" "s3bucket" {
  bucket =   "sraj-9506-${var.base_name}-bucket" 
  tags = {
    Name = "${var.base_name}_bucket"
  }      
}