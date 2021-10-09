########----- backend Bucket ---------#####
resource "aws_s3_bucket" "b" {
  bucket = join("-", [local.application.ec2, "regappbucket"])
  acl    = "private"

  tags = merge(local.common_tags,
  { Name = "Dev webapp bucket" })
}

####------- remote state file --------####
terraform {
  backend "s3" {
    bucket = "public-regappbucket"
    key    = "regwebapp"
    region = "ap-southeast-1"
  }
}