data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#Server
resource "aws_instance" "ngnixserver" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main-public-1.id
  key_name               = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  tags = merge(local.common_tags,
    { Name = "ngnixserver"
  Application = "public" })

  # user_data = file("scripts/userdata.sh")
  connection {
    # The default username for our AMI
    user        = "ubuntu"
    host        = self.public_ip
    type        = "ssh"
    private_key = file(var.path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt install apache2 -y",
      "sudo systemctl start apache2",
    ]
  }
}

#LB
resource "aws_lb" "ngnixlb" {
  name               = join("-", [local.application.app_name, "ngnixlb"])
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main_sg.id, aws_security_group.main_sgweb.id]
  subnets            = [aws_subnet.main-public-1.id, aws_subnet.main-public-2.id]
  idle_timeout       = "60"

  access_logs {
    bucket  = aws_s3_bucket.logs_s3.bucket
    prefix  = join("-", [local.application.app_name, "ngnixlb-s3logs"])
    enabled = true
  }
  tags = merge(local.common_tags,
    { Name = "ngnixserver"
  Application = "public" })
}
resource "aws_lb_target_group" "ngnixapp_tglb" {
  name     = join("-", [local.application.app_name, "ngnixapptglb"])
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/orders/index.hmtl"
    port                = "traffic-port"
    protocol            = "HTTPS"
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    timeout             = "5"
    interval            = "30"
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "ngnixapp_tglbat" {
  target_group_arn = aws_lb_target_group.ngnixapp_tglb.arn
  target_id        = aws_instance.ngnixserver.id
  port             = 443
}

resource "aws_lb_listener" "ngnixapp_lblist2" {
  load_balancer_arn = aws_lb.ngnixlb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-southeast-1:901445516958:certificate/7c0124eb-0703-42dd-b1e8-54de2d83ad3a"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ngnixapp_tglb.arn
  }
}

resource "aws_lb_listener" "ngnixapp_lblist1" {
  load_balancer_arn = aws_lb.ngnixlb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_s3_bucket" "logs_s3" {
  bucket = join("-", [local.application.app_name, "logss3"])
  acl    = "private"

  tags = merge(local.common_tags,
    { Name = "ngnixserver"
  bucket = "private" })
}
resource "aws_s3_bucket_policy" "logs_s3" {
  bucket = aws_s3_bucket.logs_s3.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "MYBUCKETPOLICY"
    Statement = [
      {
        Sid       = "Allow"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.logs_s3.arn,
          "${aws_s3_bucket.logs_s3.arn}/*",
        ]
        Condition = {
          NotIpAddress = {
            "aws:SourceIp" = "8.8.8.8/32"
          }
        }
      },
    ]
  })
}

#IAM
resource "aws_iam_role" "ngnix_role" {
  name = join("-", [local.application.app_name, "ngnixrole"])

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(local.common_tags,
    { Name = "ngnixserver"
  Role = "ngnixrole" })
}

resource "aws_iam_instance_profile" "ngnix_profile" {
  name = join("-", [local.application.app_name, "ngnixprofile"])
  role = aws_iam_role.ngnix_role.name
}
resource "aws_iam_role_policy" "ngnix_policy" {
  name = join("-", [local.application.app_name, "ngnixpolicy"])
  role = aws_iam_role.ngnix_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

#Cert
resource "aws_acm_certificate" "ngnixcert" {
  domain_name       = "elietesolutionsit.de"
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
  tags = merge(local.common_tags,
    { Name = "ngnixdummyapp"
  Cert = "ngnixcert" })
}

##Cert Validation
data "aws_route53_zone" "main-zone" {
  name         = "elietesolutionsit.de"
  private_zone = false
}

resource "aws_route53_record" "ngnixzone_record" {
  for_each = {
    for dvo in aws_acm_certificate.ngnixcert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main-zone.zone_id
}

resource "aws_acm_certificate_validation" "ngnixcert" {
  certificate_arn         = aws_acm_certificate.ngnixcert.arn
  validation_record_fqdns = [for record in aws_route53_record.ngnixzone_record : record.fqdn]
}