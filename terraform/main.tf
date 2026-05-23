# Tell Terraform to use AWS and which region
provider "aws" {
  region = var.aws_region
}

# ─────────────────────────────────────────
# NETWORKING
# ─────────────────────────────────────────

# VPC — your private network in AWS
# Think of it as your own isolated section of the cloud
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway — connects your VPC to the internet
# Without this, nothing inside your VPC can reach the outside world
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet — a slice of your VPC where resources get public IPs
# We use one availability zone, ap-southeast-1a
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Route Table — rules for how traffic flows out of the subnet
# This rule says: send all internet traffic (0.0.0.0/0) to the internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rt"
  }
}

# Associate the route table with the subnet
# Without this, the subnet doesn't know to use those routing rules
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ─────────────────────────────────────────
# SECURITY GROUP
# ─────────────────────────────────────────

# Security Group — acts as a firewall for your EC2 instance
# You define what traffic is allowed IN (ingress) and OUT (egress)
resource "aws_security_group" "main" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH, HTTP, and monitoring ports"
  vpc_id      = aws_vpc.main.id

  # SSH — port 22
  # Allows you to connect to the server from your terminal
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  # HTTP — port 80
  # Allows normal web traffic to your app
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana — port 3000
  # Allows you to open Grafana in your browser
  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus — port 9090
  # Allows you to open Prometheus UI in your browser
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Your app — port 3001
  # The Express/Flask API you'll build in Step 3
  ingress {
    description = "App"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # cAdvisor — port 8080
  ingress {
    description = "cAdvisor"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress — allow all outbound traffic
  # Your server needs to download packages, talk to the internet, etc.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# ─────────────────────────────────────────
# SSH KEY PAIR
# ─────────────────────────────────────────

# Generate an SSH key pair automatically
# Terraform creates the key, AWS stores the public half
# You get the private key to SSH into your server
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.main.public_key_openssh
}

# Save the private key to your local machine as a .pem file
resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/cloudwatch-stack-key.pem"
  file_permission = "0400"
}

# ─────────────────────────────────────────
# EC2 INSTANCE
# ─────────────────────────────────────────

# Look up the latest Ubuntu 22.04 AMI automatically
# So you don't have to hardcode an AMI ID that might expire
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu's official AWS account)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# The EC2 instance — your actual server
resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = aws_key_pair.main.key_name

  # userdata.sh runs automatically when the server first boots
  # It installs Docker and Docker Compose without you having to SSH in manually
  user_data = file("${path.module}/userdata.sh")

  # 20GB disk — within free tier limit of 30GB
  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "${var.project_name}-server"
  }
}