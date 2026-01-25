# --- Role da Aplicação (Acesso ao Postgres) ---
resource "aws_iam_role" "application_role" {
  name               = var.application_role_name
  assume_role_policy = file("${path.module}/iamsr/trust/trust-application-ec2.json")
}

resource "aws_iam_policy" "application_postgres_policy" {
  name        = "${var.application_role_name}-postgres-policy"
  description = "Policy para a aplicação acessar o Postgres via IAM Auth"
  policy      = file("${path.module}/iamsr/policy/policy-application-postgres.json")
}
resource "aws_iam_policy" "application_external_policy" {
  name        = "${var.application_role_name}-external-policy"
  description = "Policy para a aplicação acessar o externalsecret via IAM Auth"
  policy      = file("${path.module}/iamsr/policy/policy-external.json")
}
resource "aws_iam_role_policy_attachment" "application_postgres_attachment" {
  role       = aws_iam_role.application_role.name
  policy_arn = aws_iam_policy.application_postgres_policy.arn
}

resource "aws_iam_role_policy_attachment" "application_external_attachment" {
  role       = aws_iam_role.application_role.name
  policy_arn = aws_iam_policy.application_external_policy.arn
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