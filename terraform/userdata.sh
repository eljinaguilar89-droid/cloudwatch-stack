#!/bin/bash

# Update the package list
apt-get update -y

# Install required packages
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  git

# Add Docker's official GPG key (verifies the download is legit)
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker's repository to apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Docker Compose plugin
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker and enable it to start on reboot
systemctl start docker
systemctl enable docker

# Add the ubuntu user to the docker group
# So you can run docker commands without sudo when you SSH in
usermod -aG docker ubuntu

# Create the project directory
mkdir -p /home/ubuntu/cloudwatch-stack
chown ubuntu:ubuntu /home/ubuntu/cloudwatch-stack

# Log that userdata finished successfully
echo "userdata.sh completed at $(date)" >> /var/log/userdata.log