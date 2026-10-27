# Latest Ubuntu 24.04 LTS image, published by Canonical via SSM
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_instance" "this" {
  count                  = var.instance_count
  ami                    = data.aws_ssm_parameter.ubuntu.value
  instance_type          = var.instance_type
  subnet_id              = element(var.subnet_ids, count.index)
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  lifecycle {
    ignore_changes = [ami] # don't rebuild servers every time a new image is published
  }

  tags = {
    Name = "${var.name}-${var.role}-${count.index + 1}"
    Role = var.role
  }
}
