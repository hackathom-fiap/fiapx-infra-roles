# --- Variáveis Gerais ---
aws_region   = "us-east-1"
s3_bucket_name = "fiapx-video"

# --- Dados do Cluster EKS ---
# Use o ID do seu cluster aqui (obtido via kubectl cluster-info)
oidc_provider_url = "https://oidc.eks.us-east-1.amazonaws.com/id/B593E3DC270823509D0B061BFFB15EF0"
oidc_provider_arn = "arn:aws:iam::239409137076:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/B593E3DC270823509D0B061BFFB15EF0"

# --- Nomes das Roles ---
api_app_role_name    = "hackathon-fiapx-app-role"
worker_app_role_name = "hackathon-fiapx-app-role"
deploy_role_name     = "role-eks-fiap"
