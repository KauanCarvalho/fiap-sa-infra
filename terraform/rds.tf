resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL access only from EKS nodes"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "Allow MySQL from within VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-only-eks"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = data.aws_subnets.subnets.ids

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "rds_mysql_order_service" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = var.mysql_order_db_name
  username               = var.mysql_order_db_username
  password               = var.mysql_order_db_password
  skip_final_snapshot    = true
  publicly_accessible    = false

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "rds-mysql-order-service"
    Type = "order-service"
  }

  depends_on = [
    aws_db_subnet_group.rds,
    aws_security_group.rds_sg
  ]
}

resource "aws_db_instance" "rds_mysql_product_service" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = var.mysql_product_db_name
  username               = var.mysql_product_db_username
  password               = var.mysql_product_db_password
  skip_final_snapshot    = true
  publicly_accessible    = false

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "rds-mysql-product-service"
    Type = "product-service"
  }

  depends_on = [
    aws_db_subnet_group.rds,
    aws_security_group.rds_sg
  ]
}
