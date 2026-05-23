output "server_public_ip" {
  description = "Public IP of your EC2 instance"
  value       = aws_instance.main.public_ip
}

output "ssh_command" {
  description = "Copy-paste this to SSH into your server"
  value       = "ssh -i cloudwatch-stack-key.pem ubuntu@${aws_instance.main.public_ip}"
}

output "grafana_url" {
  description = "Open this in your browser to see Grafana"
  value       = "http://${aws_instance.main.public_ip}:3000"
}

output "prometheus_url" {
  description = "Open this in your browser to see Prometheus"
  value       = "http://${aws_instance.main.public_ip}:9090"
}

output "app_url" {
  description = "Your API endpoint"
  value       = "http://${aws_instance.main.public_ip}:3001"
}