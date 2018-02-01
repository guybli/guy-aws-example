provider "aws" {
  region = "${var.region}"
}

module "vpc" {
  source        = "github.com/turnbullpress/tf_vpc.git?ref=v0.0.1"
  name          = "web"
  cidr          = "10.0.0.0/16"
  public_subnet = "10.0.1.0/24"
}

data "template_file" "index" {
  count    = "${length(var.instance_ips)}"
  template = "${file("files/index.html.tpl")}"

  vars {
    hostname = "web-${format("%03d", count.index + 1)}"
  }
}

resource "aws_instance" "web" {
  ami                         = "${lookup(var.ami, var.region)}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  subnet_id                   = "${module.vpc.public_subnet_id}"
  private_ip                  = "${var.instance_ips[count.index]}"
  user_data                   = "${file("files/web_bootstrap.sh")}"
  associate_public_ip_address = true

  vpc_security_group_ids = [
    "${aws_security_group.web_host_sg.id}",
  ]

  tags {
    Name = "web-${format("%03d", count.index + 1)}"
  }

  count = "${length(var.instance_ips)}"

  connection {
    user        = "ubuntu"
    private_key = "${file(var.key_path)}"
    agent       = false
  }

  provisioner "file" {
    content = "${element(data.template_file.index.*.rendered,
count.index)}"

    destination = "/tmp/index.html"
  }

  provisioner "file" {
    content     = "${file("files/server.js")}"
    destination = "/tmp/server.js"
  }

  provisioner "file" {
    content     = "${file("files/package.json")}"
    destination = "/tmp/package.json"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/index.html /var/www/html/index.html" ,
      "sudo service nginx start"
    ]
  }
}

resource "aws_elb" "web" {
  name = "web-elb"

  subnets = ["${module.vpc.public_subnet_id}"]

   security_groups = ["${aws_security_group.web_inbound_sg.id}"]
  # security_groups = ["${aws_security_group.web_host_sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  # The instances are registered automatically
  instances = ["${aws_instance.web.*.id}"]
}

resource "aws_security_group" "web_inbound_sg" {
  name        = "web_inbound"
  description = "Allow HTTP from Anywhere"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 51737
    to_port     = 51737
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 51737
    to_port     = 51737
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_host_sg" {
  name        = "web_host"
  description = "Allow SSH & HTTP to web hosts"
  vpc_id      = "${module.vpc.vpc_id}"

  # HTTP access from the VPC

  ingress {
    from_port   = 51737
    to_port     = 51737
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["${module.vpc.cidr}"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${module.vpc.cidr}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 51737
    to_port     = 51737
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "elb_address" {
  value = "${aws_elb.web.dns_name}"
}

output "addresses" {
  value = ["${aws_instance.web.*.public_ip}"]
}

output "public_subnet_id" {
  value = "${module.vpc.public_subnet_id}"
}
