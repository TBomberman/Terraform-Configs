variable "build" {
#  default = "master"
  description = "This should match the build tag on the ami image."
}

locals {
  environment = "Dev"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

data "aws_ami" "selected" {
  owners   = ["self"]
  most_recent = true
  filter {
    name   = "tag:Build"
    values = ["${var.build}"]
  }
}

resource "aws_instance" "instance" {
  ami             = "${data.aws_ami.selected.id}"
  instance_type   = "t2.micro"
  security_groups = ["default", "SSH", "Web Server"]
  key_name        = "${aws_key_pair.generated_key.key_name}"
  tags = {
    Name = "${local.environment} ${var.build}"
  }

  provisioner "remote-exec" {
    inline = [
      "cd NodeHelloWorld",
      "pm2 start npm -- start",
      "sleep 20"
    ]

    connection {
      host        = "${self.public_ip}"
      type        = "ssh"
      private_key = "${tls_private_key.key.private_key_pem}"
      user        = "ec2-user"
    }
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "terraform ${local.environment}"
  public_key = "${tls_private_key.key.public_key_openssh}"
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.instance.id
  allocation_id = "${data.aws_eip.selected.id}"
}

data "aws_eip" "by_tags" {
  tags = {
    Name = "${local.environment}"
  }
}
