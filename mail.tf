provider "aws" {
    region = "us-east-2"
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    #Created Userdata script to publish the echo command to index.html
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

    #Lifecycle is to create the new instance 1st and point to new instance then proceed to delete the old instance
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name //calling launch configuration
    vpc_zone_identifier = data.aws_subnet_ids.default.ids   //using the subnets that are identified in subnet id's

    target_group_arns = [aws_lb_target_group.asg.arn]   //Target group resources 
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag { 
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true

    }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

variable "server_port" {
    description = "The port the server will use for HTTP request"
    type = number
    default = 80
}

#Querying for default VPC id
data "aws_vpc" "default" {
    default = true
}

#querying for subnet details in the VPC
data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}

#Creating ALB(Application LB)
resource "aws_lb" "example" {
    name = "terraform-asg-example"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.alb.id]
}

#Defining the listener for the LB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  #by default , return a simple 404 page
  default_action {
      type = "fixed-response"

      fixed_response {
          content_type = "text/plain"
          message_body = "404: page not found"
          status_code = 404
      }
  }
}

#security group for load balance to allow the ports to respond
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  #allow inbound HTTP requests
  ingress {
      from_port = 80
      to_port = 80
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
  }
  #allow all outbound requests
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

#Target group resources 
resource "aws_lb_target_group" "asg" {
    name = "terraform-asg-example"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    #defining healthprobe
    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
  
}

#ALB Listener Rule
resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100
    condition {
        path_pattern {
        values = ["*"]
        }
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
  
}

output "alb_dns_name" {
    value = aws_lb.example.dns_name
    description = "the domain name of the loadbalancer"
}