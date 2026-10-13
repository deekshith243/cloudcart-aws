resource "random_password" "jwt" {
  length  = 64
  special = true
}

resource "aws_secretsmanager_secret" "database_url" {
  count                   = var.enable_rds ? 1 : 0
  name                    = "${local.name_prefix}/database-url"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "database_url" {
  count     = var.enable_rds ? 1 : 0
  secret_id = aws_secretsmanager_secret.database_url[0].id
  secret_string = jsonencode({
    DATABASE_URL = "postgresql://${var.database_username}:${urlencode(random_password.database[0].result)}@${aws_db_instance.postgres[0].address}:${aws_db_instance.postgres[0].port}/${var.database_name}?schema=public"
  })
}

resource "aws_secretsmanager_secret" "jwt" {
  name                    = "${local.name_prefix}/jwt-secret"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "jwt" {
  secret_id = aws_secretsmanager_secret.jwt.id
  secret_string = jsonencode({
    JWT_SECRET = random_password.jwt.result
  })
}