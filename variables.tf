variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
  default = "ap-southeast-1"
}
variable "path_to_public_key" {
  description = "public key"
  default     = "ngnixkey.pub"
}

variable "path_to_private_key" {
  description = "private key"
  default     = "ngnixkey"
}
variable "ami" {
  type = map(any)
  default = {
    ap-southeast-1 = "ami-0d058fe428540cd89"
  }
}
variable "instance_type" {
  default = "t2.micro"
}
variable "path" {
  description = "private key"
  default     = "ngnixkey.pem"
}