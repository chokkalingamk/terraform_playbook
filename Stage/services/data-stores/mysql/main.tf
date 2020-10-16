provider "aws" {
    region = "us-east-2"
}

resource "aws_db_instance" "example" {
    identifier_prefix = "terraform-up-and-running"
    engine   = "mysql"
    allocated_storage = 10
    instance_class = "db.t2.micro"
    name    = "example_database"
    username = "admin"

    #how should we set the password?
    password = data.aws_secretsmanager_secret_version.db_password.secret_string
   # password = "data.aws_secretsmanager"
    skip_final_snapshot = true
}


### retrieve secret from secrets manager

data "aws_secretsmanager_secret" "db_password" {
  name = "mysql-master-password-stage"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-chokk"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true

  }
}

/*
### store db credentials in secrets manager

resource "aws_secretsmanager_secret" "db_password" {
  name = "mysql-db-master-password"
  recovery_window_in_days = 0

  #tags = module.label.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id      = aws_secretsmanager_secret.db_password.id
  secret_string  = var.db_password
  version_stages = ["AWSCURRENT"]
}


### retrieve secret 

data "aws_secretsmanager_secret" "db_password" {
  arn = aws_secretsmanager_secret.db_password.arn
}
*/


