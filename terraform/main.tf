# --- Busca os outputs do módulo EKS ---
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket         = "meu-eks-terraform-state"       # Substitua pelo nome do seu bucket S3
    key            = "soat-tech-challenge/eks.tfstate" # Caminho do arquivo de estado dentro do bucket
    region         = "us-east-1"                       # Região do seu bucket S3
    dynamodb_table = "meu-eks-terraform-lock-001"           # Substitua pelo nome da sua tabela do DynamoDB para lock
    encrypt        = true
  }
}

# --- Busca os detalhes do provedor OIDC do EKS ---
data "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url = data.terraform_remote_state.eks.outputs.oidc_provider_url
}

# --- Locais para ARNs de Segredos ---
locals {
  secrets_arns = [
    "arn:aws:secretsmanager:us-east-1:239409137076:secret:rds!db-19ace569-6ef1-4359-a00a-00fd84881fa2-UJ9RVK",
    "arn:aws:secretsmanager:us-east-1:239409137076:secret:fiapx-rabbitmq-password-alPhpo",
    "arn:aws:secretsmanager:us-east-1:239409137076:secret:/fiapx-redis/redis/user_password-v2"
  ]

  # Common Assume Role Policy for IRSA
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks_oidc_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:sub" = [
              "system:serviceaccount:fiapx-api:api-service-account",
              "system:serviceaccount:fiapx-worker:worker-service-account"
            ]
          }
        }
      }
    ]
  })
}

# --- IAM Role para a Aplicação API ---
resource "aws_iam_role" "api_app_role" {
  name               = var.api_app_role_name
  assume_role_policy = local.assume_role_policy
}

resource "aws_iam_policy" "api_secrets_policy" {
  name        = "${var.api_app_role_name}-secrets-policy"
  description = "Policy para a API acessar segredos no Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = local.secrets_arns
      }
    ]
  })
}

resource "aws_iam_policy" "api_s3_policy" {
  name        = "${var.api_app_role_name}-s3-policy"
  description = "Policy para a API acessar o S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket" # Needs ListBucket on bucket ARN, not object ARNs
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_secrets_attachment" {
  role       = aws_iam_role.api_app_role.name
  policy_arn = aws_iam_policy.api_secrets_policy.arn
}

resource "aws_iam_role_policy_attachment" "api_s3_attachment" {
  role       = aws_iam_role.api_app_role.name
  policy_arn = aws_iam_policy.api_s3_policy.arn
}


# --- IAM Role para a Aplicação Worker ---
resource "aws_iam_role" "worker_app_role" {
  name               = var.worker_app_role_name
  assume_role_policy = local.assume_role_policy
}

resource "aws_iam_policy" "worker_secrets_policy" {
  name        = "${var.worker_app_role_name}-secrets-policy"
  description = "Policy para o Worker acessar segredos no Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = local.secrets_arns
      }
    ]
  })
}

resource "aws_iam_policy" "worker_s3_policy" {
  name        = "${var.worker_app_role_name}-s3-policy"
  description = "Policy para o Worker acessar o S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket" # Needs ListBucket on bucket ARN, not object ARNs
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_secrets_attachment" {
  role       = aws_iam_role.worker_app_role.name
  policy_arn = aws_iam_policy.worker_secrets_policy.arn
}

resource "aws_iam_role_policy_attachment" "worker_s3_attachment" {
  role       = aws_iam_role.worker_app_role.name
  policy_arn = aws_iam_policy.worker_s3_policy.arn
}


# --- Role de Deploy (GitHub Actions) ---
# Mantendo a role de deploy existente
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