output "web_server_1_public_ip" {
  value       = aws_instance.web-server-1.public_ip
  description = "The public IP of web-server-1"
}

output "web_server_2_public_ip" {
  value       = aws_instance.web-server-2.public_ip
  description = "The public IP of web-server-2"
}

output "load_balancer_dns_name" {
  value       = aws_lb.test-project.dns_name
  description = "The DNS name of the load balancer"
}
