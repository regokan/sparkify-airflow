resource "aws_vpc" "sparkify_vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "sparkify_vpc"
    Project = "sparkify"
    Owner   = "DataEngg"
  }
}

resource "aws_subnet" "sparkify_subnet1" {
  vpc_id                  = aws_vpc.sparkify_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "sparkify_subnet1"
    Project = "sparkify"
    Owner   = "DataEngg"
  }
}

resource "aws_subnet" "sparkify_subnet2" {
  vpc_id                  = aws_vpc.sparkify_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "sparkify_subnet2"
    Project = "sparkify"
    Owner   = "DataEngg"
  }
}

resource "aws_subnet" "sparkify_subnet3" {
  vpc_id                  = aws_vpc.sparkify_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name    = "sparkify_subnet3"
    Project = "sparkify"
    Owner   = "DataEngg"
  }
}

resource "aws_redshift_subnet_group" "sparkify_redshift_subnet_group" {
  name = "sparkify-redshift-subnet-group"
  subnet_ids = [
    aws_subnet.sparkify_subnet1.id,
    aws_subnet.sparkify_subnet2.id,
    aws_subnet.sparkify_subnet3.id
  ]

  tags = {
    Name    = "sparkify_redshift_subnet_group"
    Project = "sparkify"
    Owner   = "DataEngg"
  }
}

resource "aws_security_group" "sparkify_redshift_security_group" {
  name        = "sparkify_security_group"
  description = "Security group for AWS Batch"
  vpc_id      = aws_vpc.sparkify_vpc.id

  # Inbound rules
  # Allow SSH (port 22) from everywhere by default
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Redshift (port 5439) from everywhere
  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules
  # Allow all outbound traffic by default
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "sparkify_security_group"
    Project = "sparkify"
    Owner   = "DataEngg"
  }
}

resource "aws_internet_gateway" "sparkify_igw" {
  vpc_id = aws_vpc.sparkify_vpc.id

  tags = {
    Name    = "sparkify_igw"
    Project = "sparkify"
    Owner   = "DataEngg"
  }
}

resource "aws_route_table" "sparkify_route_table" {
  vpc_id = aws_vpc.sparkify_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sparkify_igw.id
  }

  tags = {
    Name    = "sparkify_route_table"
    Project = "sparkify"
    Owner   = "DataEngg"
  }
}

resource "aws_route_table_association" "sparkify_assoc_subnet1" {
  subnet_id      = aws_subnet.sparkify_subnet1.id
  route_table_id = aws_route_table.sparkify_route_table.id
}

resource "aws_route_table_association" "sparkify_assoc_subnet2" {
  subnet_id      = aws_subnet.sparkify_subnet2.id
  route_table_id = aws_route_table.sparkify_route_table.id
}
