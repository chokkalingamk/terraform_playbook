provider {
    aws 
}

resource "aws_instance" "web" {
    ami= "centos"
    instance_type="t2.micro"
}