# Output para o ARN da Role da Aplicação API
output "api_app_role_arn" {
  description = "O ARN da IAM role para a Aplicação API."
  value       = aws_iam_role.api_app_role.arn
}

# Output para o ARN da Role da Aplicação Worker
output "worker_app_role_arn" {
  description = "O ARN da IAM role para a Aplicação Worker."
  value       = aws_iam_role.worker_app_role.arn
}

# Output para o ARN da Role de Deploy
output "iam_deploy_role_arn" {
  description = "O ARN da IAM role de Deploy."
  value       = aws_iam_role.deploy_role.arn
}

