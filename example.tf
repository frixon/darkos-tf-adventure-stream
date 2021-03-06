provider "aws" {
  profile = "default"
  region = "eu-west-1"
}

# --- compute ---
resource "aws_instance" "myTerraFormInstance" {
  ami           = "ami-07d9160fa81ccffb5"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  subnet_id = aws_subnet.subnet01.id
  associate_public_ip_address = true
  user_data = file("userdata.sh")
  tags = {
    Name = "TFWebServer"
  }
}

# --- networking ---

## VPC
resource "aws_vpc" "tfVPC" {
  cidr_block ="10.0.0.0/16"

  tags = {
    Name = "TFVPC"
  }
}

## Internet Gateway
resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.tfVPC.id

  tags = {
    Name = "main"
  }
}

## Subnet
resource "aws_subnet" "subnet01" {
  vpc_id =  aws_vpc.tfVPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "subnet01"
  }
}

## Route Table
resource "aws_route_table" "TFRouteTable" {
  vpc_id = aws_vpc.tfVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gw.id
  }

  tags = {
    Name = "main"
  }
}

## Route Table Association
resource "aws_route_table_association" "RTTFAssoc" {
  subnet_id = aws_subnet.subnet01.id
  route_table_id = aws_route_table.TFRouteTable.id

}

## Security Group
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.tfVPC.id

  ingress {
    description = "HTTP from the Internet"
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

  tags = {
    Name = "allow_http"
  }
}

# --- output ---

output "instance_ip_addr" {
  value       = aws_instance.myTerraFormInstance.public_ip
  description = "The private IP address of the main server instance."
}
