provider "aws" {
  region = "ap-south-1"
}


data "aws_availability_zones" "available" {}


resource "aws_vpc" "prod_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Prod_VPC"
  }
}

# Create a Public Subnet in the first available AZ
resource "aws_subnet" "prod_public_subnet" {
  vpc_id                  = aws_vpc.prod_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0] # Picks the first available AZ

  tags = {
    Name = "Prod-subnet-Public-1"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "prod_igw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "Prod-IGW"
  }
}

# Create a Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "Prod-Public-RT"
  }
}

# Add a Route for Internet Access
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.prod_igw.id
}

# Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.prod_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create a Security Group (Open to Everywhere)
resource "aws_security_group" "open_sg" {
  vpc_id = aws_vpc.prod_vpc.id

  # Allow all inbound traffic (Not recommended for production)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Open-SG"
  }
}

# data "aws_iam_instance_profile" "s3-access-profile" {
#   name = "s3-access-profile"
# }

resource "aws_instance" "Kind-Cluster" {
  ami                    = "ami-03bb6d83c60fc5f7c"
  instance_type          = "t2.medium"
  key_name               = "testing-dev-1"
  subnet_id              = aws_subnet.prod_public_subnet.id
  vpc_security_group_ids = [aws_security_group.open_sg.id]
  # user_data              = file("docker.sh")

  #  Set root volume size to 25GB
  root_block_device {
    volume_size           = 25    # Size in GB
    volume_type           = "gp3" # General Purpose SSD (default is gp2)
    delete_on_termination = true  # Deletes volume when instance is terminated
  }
  tags = {
    Name = "Kind-Cluster"
  }
}

# Outputs
output "Kind-Cluster_public_ip" {
  value = aws_instance.Kind-Cluster.public_ip
}
