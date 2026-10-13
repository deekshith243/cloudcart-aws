resource "aws_db_subnet_group" "rds" {
  count      = var.enable_rds ? 1 : 0
  name       = "${local.name_prefix}-rds"
  subnet_ids = aws_subnet.private[*].id
}

resource "random_password" "database" {
  count            = var.enable_rds ? 1 : 0
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "aws_db_instance" "postgres" {
  count                   = var.enable_rds ? 1 : 0
  identifier              = local.name_prefix
  engine                  = "postgres"
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  max_allocated_storage   = 100
  storage_encrypted       = true
  db_name                 = var.database_name
  username                = var.database_username
  password                = random_password.database[0].result
  port                    = 5432
  db_subnet_group_name    = aws_db_subnet_group.rds[0].name
  vpc_security_group_ids  = [aws_security_group.rds[0].id]
  publicly_accessible     = false
  skip_final_snapshot     = var.rds_skip_final_snapshot
  deletion_protection     = false
  backup_retention_period = 7
  multi_az                = false
  apply_immediately       = true
}