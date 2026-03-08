# Output para o ARN da Role Genérica da Aplicação (Auth, API, Worker)
output "app_generic_role_arn" {
  description = "O ARN da IAM role genérica para as aplicações."
  value       = aws_iam_role.app_generic_role.arn
}

# Output para o ARN da Role do External Secrets Operator
output "external_secrets_role_arn" {
  description = "O ARN da IAM role para o External Secrets Operator."
  value       = aws_iam_role.external_secrets_role.arn
}

# Output para o ARN da Role de Deploy
output "iam_deploy_role_arn" {
  description = "O ARN da IAM role de Deploy."
  value       = aws_iam_role.deploy_role.arn
}
