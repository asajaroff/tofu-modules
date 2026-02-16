locals {
  # Use custom AMI if provided, otherwise look up the AMI for the selected os_family
  selected_ami = var.custom_ami_id != null ? var.custom_ami_id : one(
    var.os_family == "debian" ? data.aws_ami.debian[*].id :
    var.os_family == "ubuntu" ? data.aws_ami.ubuntu[*].id :
    var.os_family == "freebsd" ? data.aws_ami.freebsd[*].id :
    data.aws_ami.flatcar[*].id
  )
}

data "aws_ami" "ubuntu" {
  count       = var.custom_ami_id == null && var.os_family == "ubuntu" ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-${var.os_arch}-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

data "aws_ami" "debian" {
  count       = var.custom_ami_id == null && var.os_family == "debian" ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["debian-13-${var.os_arch}-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["136693071363"] # https://wiki.debian.org/Cloud/AmazonEC2Image/
}

# https://eu-west-1.console.aws.amazon.com/ec2/home?region=eu-west-1#Images:visibility=public-images;imageName=:FreeBSD%2014.1-STABLE-;v=3;$case=tags:false%5C,client:false;$regex=tags:false%5C,client:false
data "aws_ami" "freebsd" {
  count       = var.custom_ami_id == null && var.os_family == "freebsd" ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["FreeBSD 14.1-STABLE-${var.os_arch}-* base UFS"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["782442783595"] # https://wiki.debian.org/Cloud/AmazonEC2Image/
}

# https://www.flatcar.org/docs/latest/installing/cloud/aws-ec2/
data "aws_ami" "flatcar" {
  count       = var.custom_ami_id == null && var.os_family == "flatcar" ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["Flatcar-stable-*-hvm"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = [var.os_arch == "amd64" ? "x86_64" : "arm64"]
  }
  owners = ["075585003325"] # Official Flatcar Container Linux
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}
