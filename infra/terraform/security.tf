resource "aws_security_group" "servicehub" {
  name        = "${local.name_prefix}-web"
  description = "Public web access for ServiceHub; administration uses SSM by default"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-web"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.servicehub.id
  description       = "Public HTTP to NGINX"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  count = var.enable_https_ingress ? 1 : 0

  security_group_id = aws_security_group.servicehub.id
  description       = "Public HTTPS to NGINX"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  count = var.ssh_allowed_cidr == null ? 0 : 1

  security_group_id = aws_security_group.servicehub.id
  description       = "Optional emergency SSH from one trusted public IP"
  cidr_ipv4         = var.ssh_allowed_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.servicehub.id
  description       = "Outbound access for OS updates, SSM, and ECR"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
