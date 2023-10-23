terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.22.0"
    }
  }
}

provider "aws" {
    region = "sa-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-01"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "subnet-01"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "ig-01"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = {
    Name = "route-table-01"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}


resource "aws_key_pair" "deployer" {
  key_name   = "devops"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAU0DSnHpLEB+G2+31aRYmJ1NQYOBsjqMPVks0Db8D7+ wsl-casa"
  #Pegar a chave publica da tua maquina
}

resource "aws_instance" "web" {
  ami           = "ami-0b6c2d49148000cd5"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet.id
  associate_public_ip_address = true
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.security_group.id]
  
  tags = {
    Name = "ec2-01"
  }
}

resource "aws_security_group" "security_group" {
  name        = "GS_ec2-01"
  description = "Grupo de Seguranca - Liberando"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "Liberacao da porta 22"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  ingress {
    description      = "Liberacao da porta 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Liberacao da porta 443"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "GS_ec2-01"
  }
}
output "ip-ec2" {
  value = aws_instance.web.public_ip
}