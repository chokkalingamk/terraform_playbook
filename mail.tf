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
    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = data.aws_subnet_ids.default.ids

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
/*
output "public_ipaddr" {
    description = "The public ip address of the webserver"
    value = aws_instance.example.public_ip
}

output "private_ipaddr" {
    description = "The public ip address of the webserver"
    value = aws_instance.example.private_ip
}
*/
#Querying for default VPC id
data "aws_vpc" "default" {
    default = true
}

#querying for subnet details in the VPC
data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}


/*
provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "example" {
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id] //referrance for accesing security group

#Created Userdata script to publish the echo command to index.html
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

    tags = {
        Name = "terraform-example"
    }
}

#Security Group creation
/*resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
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

output "public_ipaddr" {
    description = "The public ip address of the webserver"
    value = aws_instance.example.public_ip
}

output "private_ipaddr" {
    description = "The public ip address of the webserver"
    value = aws_instance.example.private_ip
}
*/