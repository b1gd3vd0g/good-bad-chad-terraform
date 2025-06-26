resource "aws_db_instance" "postgres" {
  identifier          = "goodbadchad"
  engine              = "postgres"
  instance_class      = "db.t4g.micro"
  allocated_storage   = "10"
  publicly_accessible = true
  skip_final_snapshot = true # TODO: Change for production!!
  deletion_protection = false

  username = var.pg_username
  password = var.pg_password
  db_name  = var.db_name

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
}

output "db_path" {
  value = aws_db_instance.postgres.address
}
