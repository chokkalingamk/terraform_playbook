provider "aws" {
    region = "us-east-2"
    access_key = "AKIA2MBBR6XQPOLPLYSZ"
    secret_key = "O3fYnMpRMfS+bYbiZ+z8qtUYKRLkscgM3zZx+6BR"
}

resource "aws_instance" "example" {
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id] //referrance for accesing security group

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF

    tags = {
        Name = "terraform-example"
    }
}

#Security Group creation
resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}