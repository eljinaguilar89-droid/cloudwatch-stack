variable "aws_region" {
  description = "AWS region to deploy into"
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "EC2 instance size"
  default     = "t2.micro"
}

variable "project_name" {
  description = "Name tag applied to all resources"
  default     = "cloudwatch-stack"
}

variable "your_ip" {
  description = "Your local IP for SSH access. Get it from whatismyip.com"
  default     = "0.0.0.0/0"
}