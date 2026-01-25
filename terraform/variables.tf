# Variável para a Role da Aplicação
variable "application_role_name" {
  description = "Nome da IAM role para a aplicação (ex: para acesso ao DB)."
  type        = string
  default     = "iam-application-role"
}

# Variável para a Role de Deploy do GitHub Actions
variable "deploy_role_name" {
  description = "Nome da IAM role para o deploy via GitHub Actions."
  type        = string
  default     = "iam-github-deployer-role"
}
