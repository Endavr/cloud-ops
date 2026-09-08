output "ec2_instance_id" {
  description = "ID of the ServiceHub EC2 instance."
  value       = aws_instance.servicehub.id
}

output "ec2_public_ip" {
  description = "Public IPv4 address of the ServiceHub EC2 instance."
  value       = aws_instance.servicehub.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the ServiceHub EC2 instance."
  value       = aws_instance.servicehub.public_dns
}

output "ecr_repository_url" {
  description = "URL of the ServiceHub ECR repository."
  value       = aws_ecr_repository.servicehub.repository_url
}

output "session_manager_command" {
  description = "AWS CLI command for starting an SSM Session Manager shell."
  value       = "aws ssm start-session --target ${aws_instance.servicehub.id} --region ${var.aws_region}"
}
