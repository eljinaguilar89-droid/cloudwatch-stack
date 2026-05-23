# CloudWatch Stack

A production-style cloud monitoring platform built on AWS Free Tier.  
Automatically provisioned with Terraform and deployed via a GitHub Actions CI/CD pipeline.  
Monitors a containerized Node.js API using Prometheus and Grafana.

---

## What This Project Does

This project demonstrates a full cloud engineering workflow:

- Infrastructure is defined as code using Terraform — no clicking around in AWS
- A Node.js API is containerized with Docker and instrumented with Prometheus metrics
- Prometheus scrapes metrics from the app and Docker containers every 15 seconds
- Grafana visualizes those metrics as a live dashboard with CPU, memory, request rate, and response time
- An alert rule fires when CPU exceeds 70% for over 2 minutes
- A GitHub Actions pipeline automatically redeploys the stack on every push to main

---

## Architecture

Your Machine  
&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;terraform apply  
&nbsp;&nbsp;&nbsp;&nbsp;▼  
AWS (ap-southeast-1)  
&nbsp;&nbsp;&nbsp;&nbsp;├── VPC (10.0.0.0/16)  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;└── Public Subnet (10.0.1.0/24)  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── Internet Gateway  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── Route Table  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── EC2 t2.micro (Ubuntu 22.04)  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;Docker Compose  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── cloudwatch-app&nbsp;&nbsp;:3001  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── cAdvisor&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:8080  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── Prometheus&nbsp;&nbsp;&nbsp;&nbsp;:9090  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── Grafana&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:3000  
&nbsp;&nbsp;&nbsp;&nbsp;│  
GitHub (main branch push)  
&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;GitHub Actions  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;1. Build Docker image  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;2. Push to Docker Hub  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;3. SSH into EC2  
&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;4. docker compose pull && up -d  
&nbsp;&nbsp;&nbsp;&nbsp;▼  
Live on EC2

---

## Tech Stack

Tool                  | Purpose
----------------------|--------------------------------------------------------------
Terraform             | Provisions AWS infrastructure as code — VPC, EC2, security groups, networking
AWS EC2               | The cloud server that runs everything (t2.micro, free tier)
Docker                | Packages the app and all monitoring tools into containers
Docker Compose        | Runs all four containers together on one server
cAdvisor              | Reads Docker stats and exposes them as Prometheus-compatible metrics
Prometheus            | Scrapes and stores time-series metrics from the app and cAdvisor
Grafana               | Visualizes metrics as dashboards and manages alert rules
GitHub Actions        | CI/CD pipeline — auto-builds and deploys on every push to main
Node.js + Express     | The sample API with a /metrics endpoint for app-level instrumentation
prom-client           | Prometheus client library used to instrument the Node.js app

---

## Project Structure

cloudwatch-stack/  
├── .github/  
│&nbsp;&nbsp;└── workflows/  
│&nbsp;&nbsp;&nbsp;&nbsp;└── deploy.yml              # GitHub Actions CI/CD pipeline  
├── terraform/  
│&nbsp;&nbsp;├── versions.tf                 # Provider version locks  
│&nbsp;&nbsp;├── variables.tf                # Configurable values (region, instance type)  
│&nbsp;&nbsp;├── main.tf                     # VPC, subnet, security group, EC2  
│&nbsp;&nbsp;├── outputs.tf                  # Prints IP, SSH command, and URLs after apply  
│&nbsp;&nbsp;└── userdata.sh                 # Bootstraps Docker on first EC2 boot  
├── app/  
│&nbsp;&nbsp;├── index.js                    # Express API with /hello and /metrics endpoints  
│&nbsp;&nbsp;├── package.json  
│&nbsp;&nbsp;└── Dockerfile  
├── monitoring/  
│&nbsp;&nbsp;├── docker-compose.yml          # Runs app, cAdvisor, Prometheus, Grafana  
│&nbsp;&nbsp;├── prometheus.yml              # Scrape targets and intervals  
│&nbsp;&nbsp;└── grafana/  
│&nbsp;&nbsp;&nbsp;&nbsp;└── provisioning/  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── datasources/  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;└── prometheus.yml  # Auto-connects Prometheus to Grafana  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── dashboards/  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│&nbsp;&nbsp;└── dashboard.yml   # Tells Grafana where to find dashboards  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── dashboards-json/  
│&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── cloudwatch.json # Dashboard definition as code  
└── README.md

---

## Prerequisites

- AWS account (free tier)
- Terraform installed (terraform --version to verify)
- AWS CLI installed and configured (aws configure)
- Docker Hub account
- GitHub account

---

## How to Deploy

1. Clone the repo

    git clone https://github.com/YOURUSERNAME/cloudwatch-stack.git  
    cd cloudwatch-stack

2. Provision infrastructure with Terraform

    cd terraform  
    terraform init  
    terraform plan  
    terraform apply

    After apply completes, Terraform prints your server's IP and ready-to-use URLs:

    server_public_ip = "54.179.XXX.XXX"  
    ssh_command      = "ssh -i cloudwatch-stack-key.pem ubuntu@54.179.XXX.XXX"  
    grafana_url      = "http://54.179.XXX.XXX:3000"  
    prometheus_url   = "http://54.179.XXX.XXX:9090"  
    app_url          = "http://54.179.XXX.XXX:3001"

3. Add GitHub Secrets

    Go to your GitHub repo → Settings → Secrets and variables → Actions.

    Secret           | Value
    -----------------|------------------------------------------
    EC2_HOST         | Your EC2 public IP from Terraform output
    EC2_USER         | ubuntu
    EC2_SSH_KEY      | Full contents of cloudwatch-stack-key.pem
    DOCKER_USERNAME  | Your Docker Hub username
    DOCKER_PASSWORD  | Your Docker Hub access token

4. First deploy

    SSH into the server and start the stack manually the first time:

    ssh -i terraform/cloudwatch-stack-key.pem ubuntu@YOUR_EC2_IP  
    cd /home/ubuntu  
    git clone https://github.com/YOURUSERNAME/cloudwatch-stack.git  
    cd cloudwatch-stack/monitoring  
    docker compose up -d

    After this, all future deploys are automatic via GitHub Actions.

5. Verify everything is running

    docker compose ps

    Expected output:

    NAME              STATUS  
    cloudwatch-app    Up (healthy)  
    cadvisor          Up  
    prometheus        Up  
    grafana           Up

---

## Access the Services

Service       | URL                              | Credentials
--------------|----------------------------------|---------------------
Your App      | http://YOUR_IP:3001/hello        | None
App Metrics   | http://YOUR_IP:3001/metrics      | None
Prometheus    | http://YOUR_IP:9090              | None
Grafana       | http://YOUR_IP:3000              | admin / cloudwatch123
cAdvisor      | http://YOUR_IP:8080              | None

---

## Metrics Collected

Infrastructure metrics (via cAdvisor):
- CPU usage per container
- Memory usage per container
- Network bytes in/out per container
- Disk reads/writes per container
- Container restart count

Application metrics (via prom-client):
- http_requests_total — total requests by method, route, and status code
- http_active_requests — requests being processed right now
- http_request_duration_seconds — response time histogram per route
- Default Node.js metrics — event loop lag, garbage collection, heap size

---

## Grafana Dashboard

The dashboard loads automatically on startup — no manual setup needed.

Panels included:
- CPU Usage % — per container over time
- Memory Usage (MB) — per container over time
- App Request Rate — requests per second by route
- Avg Response Time — milliseconds per route
- Active Requests — live count of in-flight requests

To import the community Docker dashboard manually:  
Dashboards → Import → ID 193 → select Prometheus → Import.

---

## Alert Rules

Alert            | Condition    | Duration
-----------------|--------------|----------
High CPU Usage   | CPU > 70%    | 2 minutes

Alerts are sent via email using Gmail SMTP.  
Configure SMTP credentials in the Grafana service environment variables inside docker-compose.yml.

---

## CI/CD Pipeline

Every push to main triggers the GitHub Actions workflow:

Push to main  
&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;├── Checkout code  
&nbsp;&nbsp;&nbsp;&nbsp;├── Log in to Docker Hub  
&nbsp;&nbsp;&nbsp;&nbsp;├── Build Docker image from ./app  
&nbsp;&nbsp;&nbsp;&nbsp;├── Push image to Docker Hub  
&nbsp;&nbsp;&nbsp;&nbsp;└── SSH into EC2  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── docker compose pull  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── docker compose up -d  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── docker image prune -f

Total deploy time: approximately 60 seconds.

---

## Teardown

To avoid AWS charges, destroy all resources when not in use:

    cd terraform  
    terraform destroy

Type yes to confirm. This deletes the EC2 instance, VPC, subnet, security group, and key pair.  
Your code stays on GitHub — you can recreate everything in under 2 minutes with terraform apply.

---

## What This Demonstrates

JD Requirement                          | How This Project Covers It
----------------------------------------|--------------------------------------------------------------
Cloud infrastructure setup              | Terraform provisions VPC, EC2, networking, security groups on AWS
Deploy and configure resources          | Docker Compose deploys four services with proper config and persistent storage
Infrastructure as Code                  | Entire infrastructure defined in .tf files, reproducible with one command
Deployment automation and CI/CD         | GitHub Actions pipeline builds, pushes, and deploys on every push
Network setup and security              | VPC, public subnet, internet gateway, security group rules per port
Tool integration                        | Prometheus integrates with cAdvisor and the app; Grafana integrates with Prometheus
Monitoring, alerting, performance       | Prometheus scrapes metrics, Grafana dashboards visualize them, alert fires on CPU threshold

---

## Author

Eljin — BS Computer Engineering, STI College Global City  
GitHub: https://github.com/YOURUSERNAME  
LinkedIn: https://linkedin.com/in/YOURPROFILE