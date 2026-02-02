variable "api_app_role_name" {
  description = "Nome da IAM role para a aplicação API."
  type        = string
  default     = "fiapx-api-app-role"
}

variable "worker_app_role_name" {
  description = "Nome da IAM role para a aplicação Worker."
  type        = string
  default     = "fiapx-worker-app-role"
}

variable "s3_bucket_name" {
  description = "Nome do bucket S3 para armazenamento de vídeos."
  type        = string
}

variable "oidc_provider_arn" {
  description = "O ARN do provedor OIDC do cluster EKS."
  type        = string
}

variable "oidc_provider_url" {
  description = "A URL do provedor OIDC do cluster EKS."
  type        = string
}

# Variável para a Role de Deploy do GitHub Actions
variable "deploy_role_name" {
  description = "Nome da IAM role para o deploy via GitHub Actions."
  type        = string
  default     = "iam-github-deployer-role"
}

