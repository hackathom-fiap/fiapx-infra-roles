# --- Busca os outputs do módulo EKS ---
data="terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket         = "meu-eks-terraform-state"
    key            = "soat-tech-challenge/eks.tfstate"
    region         = "us-east-1"
    dynamodb_table = "meu-eks-terraform-lock-001"
    encrypt        = true
  }
}

# --- Busca os detalhes do provedor OIDC do EKS ---
data "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url = data.terraform_remote_state.eks.outputs.oidc_provider_url
}

locals {
  # --- POLÍTICA DE CONFIANÇA GENÉRICA (IRSA) ---
  # Permite que qualquer Service Account em qualquer namespace do projeto (hackathon-*) assuma a role.
  # Para máxima facilidade, usamos o wildcard "*" no namespace e no nome do Service Account.
  generic_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks_oidc_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "${replace(data.aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:sub" = [
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
# Esta role é a que o Operador usa para buscar segredos para TODO o cluster.
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
        Resource = "*" # Permissao genérica para não precisar atualizar ARNs
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eso_attachment" {
  role       = aws_iam_role.external_secrets_role.name
  policy_arn = aws_iam_policy.eso_generic_secrets_policy.arn
}

# --- ROLE GENÉRICA PARA AS APLICAÇÕES (Apps Role) ---
# Uma única role que todos os seus microsserviços podem usar.
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
        Resource = "*" # Permite acesso a buckets S3 (pode restringir por prefixo se desejar)
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
