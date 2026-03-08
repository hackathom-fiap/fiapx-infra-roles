# --- Variáveis (Definidas no terraform.tfvars) ---
variable "oidc_provider_url" {}
variable "oidc_provider_arn" {}
variable "s3_bucket_name" {}
variable "deploy_role_name" {}
variable "api_app_role_name" {}
variable "worker_app_role_name" {}
variable "aws_region" {}

# --- Blocos de Importação (Para resolver o erro EntityAlreadyExists via esteira) ---
import {
  to = aws_iam_role.external_secrets_role
  id = "hackathon-fiapx-external-secrets-role"
}

import {
  to = aws_iam_role.deploy_role
  id = "role-eks-fiap"
}

locals {
  # --- POLÍTICA DE CONFIANÇA GENÉRICA (IRSA) ---
  generic_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = [
              "system:serviceaccount:hackathon-*:*",    # Aplicações no namespace hackathon-*
              "system:serviceaccount:external-secrets:*", # Operador de Segredos
              "system:serviceaccount:fiapx-*:*"         # Compatibilidade com namespaces fiapx-*
            ]
          }
        }
      }
    ]
  })
}

# --- ROLE PARA O EXTERNAL SECRETS OPERATOR (ESO) ---
resource "aws_iam_role" "external_secrets_role" {
  name               = "hackathon-fiapx-external-secrets-role"
  assume_role_policy = local.generic_assume_role_policy
}

resource "aws_iam_policy" "eso_generic_secrets_policy" {
  name        = "external-secrets-generic-policy"
  description = "Permite ler todos os segredos do Secrets Manager para o projeto"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*" 
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eso_attachment" {
  role       = aws_iam_role.external_secrets_role.name
  policy_arn = aws_iam_policy.eso_generic_secrets_policy.arn
}

# --- ROLE GENÉRICA PARA AS APLICAÇÕES (Apps Role) ---
resource "aws_iam_role" "app_generic_role" {
  name               = "hackathon-fiapx-app-role"
  assume_role_policy = local.generic_assume_role_policy
}

resource "aws_iam_policy" "app_generic_policy" {
  name        = "hackathon-app-generic-policy"
  description = "Acesso genérico a segredos e S3 para as apps"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "*" 
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_attachment" {
  role       = aws_iam_role.app_generic_role.name
  policy_arn = aws_iam_policy.app_generic_policy.arn
}

# --- Role de Deploy (GitHub Actions) ---
resource "aws_iam_role" "deploy_role" {
  name               = var.deploy_role_name
  assume_role_policy = file("${path.module}/iamsr/trust/trust-github-actions.json")
}

resource "aws_iam_policy" "github_deployer_policy" {
  name        = "${var.deploy_role_name}-policy"
  description = "Policy para deploy de infra via GitHub Actions"
  policy      = file("${path.module}/iamsr/policy/policy-github-deployer.json")
}

resource "aws_iam_role_policy_attachment" "github_deployer_attachment" {
  role       = aws_iam_role.deploy_role.name
  policy_arn = aws_iam_policy.github_deployer_policy.arn
}
