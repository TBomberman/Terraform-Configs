variable "branch" {
  description = "This should match the branch tag on the ami image."
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

data "aws_ami" "selected" {
  owners   = ["self"]
  filter {
    name   = "tag:Build"
    values = ["${var.branch}"]
  }

  most_recent = true
}

resource "aws_instance" "instance" {
  ami = "${data.aws_ami.selected.id}"
  instance_type = "t2.micro"

  tags = {
    Name = "QA ${var.branch}"
  }
}

resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = "sg-079a7d9f8594516a7"
  network_interface_id = aws_instance.instance.primary_network_interface_id
}
