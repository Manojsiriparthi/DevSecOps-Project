# Define the VPC
resource "aws_vpc" "eks" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
}

# Define the public subnets
resource "aws_subnet" "public_subnet" {
  count                  = 2
  vpc_id                 = aws_vpc.eks.id
  cidr_block             = cidrsubnet(aws_vpc.eks.cidr_block, 8, count.index)
  availability_zone      = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-public-subnet-${count.index}"
  }
}

# Define the private subnets
resource "aws_subnet" "private_subnet" {
  count                  = 2
  vpc_id                 = aws_vpc.eks.id
  cidr_block             = cidrsubnet(aws_vpc.eks.cidr_block, 8, count.index + 2)
  availability_zone      = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "eks-private-subnet-${count.index}"
  }
}

# Define the internet gateway
resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id
  tags = {
    Name = "eks-igw"
  }
}

# Define the route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks.id
  }
  tags = {
    Name = "eks-public-route-table"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

# Define the Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  tags = {
    Name = "eks-nat-eip"
  }
}

# Define the NAT Gateway
resource "aws_nat_gateway" "eks" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags = {
    Name = "eks-nat-gateway"
  }
}

# Define the route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.eks.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks.id
  }
  tags = {
    Name = "eks-private-route-table"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}

# Data source for availability zones
data "aws_availability_zones" "available" {}

