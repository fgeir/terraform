provider "aws" {
    region = "eu-west-1"
}

####variables

variable "http_server_port" {
  description = "Port number of our webserver"
  default     = 8080
}

variable "ssh_server_port" {
  description = "Port number of our webserver"
  default     = 22
}

variable "ami_id" {
  description = "AMI-ID to use"
  default = "ami-0ab7944c6328200be"
}

variable "instance_type" {
  description = "Type of instance to use"
  default = "t2.micro"
}

data "aws_availability_zones" "all" {

}


resource "aws_elb" "webserver_elb" {
    name               = "terraform-elb-webserver"
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    security_groups    = ["${aws_security_group.elb.id}"]


    listener {
      instance_port     = "${var.http_server_port}"
      instance_protocol = "http"
      lb_port           = 80
      lb_protocol       = "http"
    }
    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "HTTP:${var.http_server_port}/"
      interval = 30
    }
}

resource "aws_autoscaling_group" "webserver_asg" {
    launch_configuration = "${aws_launch_configuration.webserver_cluster_asgconfiguration.id}"
    availability_zones   = ["${data.aws_availability_zones.all.names}"]
    load_balancers       = ["${aws_elb.webserver_elb.name}"]
    health_check_type    = "ELB"
    min_size             = 2
    max_size             = 3

    tag {
      key = "Name"
      value = "Webserver ASG"
      propagate_at_launch = true
    }
}


resource "aws_launch_configuration" "webserver_cluster_asgconfiguration" {
    name          = "webserver_launch_configuration"
    image_id      = "${var.ami_id}"
    instance_type = "${var.instance_type}"
    security_groups = ["${aws_security_group.SSH_ec2.id}"]

    user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p "${var.http_server_port}" &
            EOF
    lifecycle {
        create_before_destroy = true
    }
}


resource "aws_security_group" "SSH_ec2" {
  name = "SSH_ec2"
  ingress {
    from_port   = "${var.http_server_port}"
    to_port     = "${var.http_server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "${var.ssh_server_port}"
    to_port     = "${var.ssh_server_port}"
    protocol    = "tcp"
    cidr_blocks = ["37.228.225.146/32"]
  }

  lifecycle {
      create_before_destroy = true
  }
}

resource "aws_security_group" "elb" {

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
output "public_ip" {
    value = "${aws_elb.webserver_elb.dns_name}"
}
# resource "aws_instance" "example_paco" {
    # ami           = "ami-0ab7944c6328200be"
    # instance_type = "t2.micro"
    # vpc_security_group_ids = ["${aws_security_group.SSH_ec2.id}"]
    # user_data     = <<-EOF
                  #!/bin/bash
                  # echo "Hello, World" > index.html
                  # nohup busybox httpd -f -p "${var.server_port}" &
                  # EOF
    # tags {
      # Name              = "Instancia1",
      # SistemaOperativo  = "Ubuntu"
      # CreadoDe          = "Terraform"
    # }
# }
