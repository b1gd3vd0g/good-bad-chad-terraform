# provider "aws" {
#   region = "us-west-2"
# }

# Create a Virtual Private Cloud for your backend services to run on.
resource "aws_vpc" "gbc_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create an Internet Gateway, which allows for resources in
# PUBLIC SUBNETS to send and receive traffic from internet. 
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.gbc_vpc.id
}

# Create the subnets needed for this VPC. 
# It is good practice to always have TWO subnets for each resource to rely on,
# ensuring the highest availability for your resources.
# These subnets will contain the RDS database.
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.gbc_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.gbc_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.gbc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_db_subnet_group" "main" {
  name = "public-rds-subnet-group"
  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

resource "aws_security_group" "rds" {
  name        = "rds-public-access"
  description = "Allow public DB access"
  vpc_id      = aws_vpc.gbc_vpc.id

  ingress {
    description = "Allow PostgreSQL access from any IP address"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    # For now, I have to allow ingress from any IP address, because the Lambda
    # function is going to be declared OUTSIDE the VPC, so it will not have a
    # static IP address to add to this list:
    cidr_blocks = ["0.0.0.0/0"] # Allow all IP addresses
    # cidr_blocks = ["${var.my_ip_address}/32"] # Allow only my IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
