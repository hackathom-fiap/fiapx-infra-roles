# Este arquivo conterá os outputs do Terraform (ex: ARNs das roles)

# Output para o ARN da Role da Aplicação
output "iam_application_role_arn" {
  description = "O ARN da IAM role da Aplicação."
  value       = aws_iam_role.application_role.arn
}

# Output para o ARN da Role de Deploy
output "iam_deploy_role_arn" {
  description = "O ARN da IAM role de Deploy."
  value       = aws_iam_role.deploy_role.arn
}
