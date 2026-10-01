data "aws_ami" "ubuntu_arm64" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "servicehub" {
  ami                         = data.aws_ami.ubuntu_arm64.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.servicehub.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = var.key_name
  user_data                   = file("${path.module}/bootstrap.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  lifecycle {
    precondition {
      condition     = (var.ssh_allowed_cidr == null && var.key_name == null) || (var.ssh_allowed_cidr != null && var.key_name != null)
      error_message = "ssh_allowed_cidr and key_name must either both be set or both be null."
    }
  }

  tags = {
    Name = "${local.name_prefix}-api"
  }
}
