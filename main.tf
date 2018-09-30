provider "aws" {
    region = "eu-west-1"
}

resource "aws_instance" "example_paco" {
    ami           = "ami-0bdb1d6c15a40392c"
    instance_type = "t2.micro"
}
