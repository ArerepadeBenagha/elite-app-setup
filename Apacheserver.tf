#Server
resource "aws_instance" "httpdserver" {
  ami                    = lookup(var.ami, var.aws_region)
  # ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main-public-1.id
  key_name               = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  
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
      "sudo apt install nginx -y",
      # "sudo apt install apache2 -y",
      # "sudo systemctl start apache2",
    ]
  }
  tags = merge(local.common_tags,
    { Name = "apacheserver"
  Application = "public" })
}

##LB
resource "aws_lb" "httpdlb" {
  name               = join("-", [local.application.app_name, "httpdlb"])
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main-alb.id]
  subnets            = [aws_subnet.main-public-1.id, aws_subnet.main-public-2.id]
  idle_timeout       = "60"

  access_logs {
    bucket  = aws_s3_bucket.logs_s3.bucket
    prefix  = join("-", [local.application.app_name, "httpdlb-s3logs"])
    enabled = true
  }
  tags = merge(local.common_tags,
    { Name = "httpdserver"
  Application = "public" })
}
///ALB-HLTH CHCK
resource "aws_lb_target_group" "httpdapp_tglb" {
  name     = join("-", [local.application.app_name, "httpdapptglb"])
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    timeout             = "5"
    interval            = "30"
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "httpdapp_tglbat" {
  target_group_arn = aws_lb_target_group.httpdapp_tglb.arn
  target_id        = aws_instance.httpdserver.id
  port             = 80
}

resource "aws_lb_listener" "httpdapp_lblist2" {
  load_balancer_arn = aws_lb.httpdlb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-southeast-1:901445516958:certificate/221fff07-f36c-4944-94ef-760d4925c40e"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.httpdapp_tglb.arn
  }
}

resource "aws_lb_listener" "httpdapp_lblist" {
  load_balancer_arn = aws_lb.httpdlb.arn
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
    { Name = "httpdserver"
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
resource "aws_iam_role" "httpd_role" {
  name = join("-", [local.application.app_name, "httpdrole"])

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
    { Name = "httpdserver"
  Role = "httpdrole" })
}

resource "aws_iam_role_policy" "httpd_policy" {
  name = join("-", [local.application.app_name, "httpdpolicy"])
  role = aws_iam_role.httpd_role.id

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
resource "aws_acm_certificate" "httpdcert" {
  domain_name       = "*.elietesolutionsit.de"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = merge(local.common_tags,
    { Name = "registration-app.elietesolutionsit.de"
  Cert = "httpdcert" })
}

# ##Cert Validation
data "aws_route53_zone" "main-zone" {
  name         = "elietesolutionsit.de"
  private_zone = false
}

resource "aws_route53_record" "httpdzone_record" {
  for_each = {
    for dvo in aws_acm_certificate.httpdcert.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "httpdcert" {
  certificate_arn         = aws_acm_certificate.httpdcert.arn
  validation_record_fqdns = [for record in aws_route53_record.httpdzone_record : record.fqdn]
}

##Alias record
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main-zone.zone_id
  name    = "registration-app.elietesolutionsit.de"
  type    = "A"

  alias {
    name                   = aws_lb.httpdlb.dns_name
    zone_id                = aws_lb.httpdlb.zone_id
    evaluate_target_health = true
  }
}