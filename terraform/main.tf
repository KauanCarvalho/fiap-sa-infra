data "aws_availability_zones" "available" {}

data "aws_db_subnet_group" "existing" {
  name = "${var.cluster_name}-rds-subnet-group"
}

data "aws_eks_cluster" "existing" {
  name = var.cluster_name
}

data "aws_eks_node_groups" "all_node_groups" {
  cluster_name = var.cluster_name
}

locals {
  cluster_exists    = length(data.aws_eks_cluster.existing.id) > 0
  node_group_exists = contains(data.aws_eks_node_groups.all_node_groups.names, "${var.cluster_name}-nodes")
}

resource "aws_vpc" "this" {
  count      = local.cluster_exists ? 0 : 1
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  count  = local.cluster_exists ? 0 : 1
  vpc_id = aws_vpc.this[0].id
}

resource "aws_subnet" "public" {
  count                   = local.cluster_exists ? 0 : 2
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count                   = local.cluster_exists ? 0 : 2
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index + 10)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.cluster_name}-private-subnet-${count.index}"
  }
}

resource "aws_route_table" "public" {
  count  = local.cluster_exists ? 0 : 1
  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }
}

resource "aws_route_table_association" "public" {
  count          = local.cluster_exists ? 0 : length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_security_group" "node_group_sg" {
  count       = local.cluster_exists ? 0 : 1
  name        = "${var.cluster_name}-node-group-sg"
  description = "Security group for EKS Node Group"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-node-group-sg"
  }
}

resource "aws_eks_cluster" "this" {
  count    = local.cluster_exists ? 0 : 1
  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }

  lifecycle {
    ignore_changes  = [tags, version, kubernetes_network_config]
    prevent_destroy = true
  }
}

locals {
  eks_cluster_name = local.cluster_exists ? data.aws_eks_cluster.existing.name : aws_eks_cluster.this[0].name
}

resource "aws_eks_node_group" "this" {
  count           = local.node_group_exists ? 0 : 1
  cluster_name    = local.eks_cluster_name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = local.cluster_exists ? data.aws_eks_cluster.existing.vpc_config[0].subnet_ids : aws_subnet.public[*].id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }

  tags = {
    Name = "${var.cluster_name}-node-group"
  }
}

resource "aws_security_group" "rds_sg" {
  count       = local.cluster_exists ? 0 : 1
  name        = "${var.cluster_name}-rds-sg"
  description = "Allow EKS nodes to access RDS"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description     = "MySQL from EKS Nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.node_group_sg[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  count      = data.aws_db_subnet_group.existing.id != "" ? 0 : 1
  name       = "${var.cluster_name}-rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.cluster_name}-rds-subnet-group"
  }
}

resource "aws_db_instance" "order_service_mysql" {
  count                  = data.aws_db_subnet_group.existing.id != "" ? 0 : 1
  identifier             = "${var.cluster_name}-order-service-mysql"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.mysql_order_db_name
  username               = var.mysql_order_db_username
  password               = var.mysql_order_db_password
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg[0].id]
  db_subnet_group_name   = "${var.cluster_name}-rds-subnet-group"

  tags = {
    Name = "${var.cluster_name}-order-service-mysql"
  }
}

resource "aws_db_instance" "product_service_mysql" {
  count                  = data.aws_db_subnet_group.existing.id != "" ? 0 : 1
  identifier             = "${var.cluster_name}-product-service-mysql"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.mysql_product_db_name
  username               = var.mysql_product_db_username
  password               = var.mysql_product_db_password
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg[0].id]
  db_subnet_group_name   = "${var.cluster_name}-rds-subnet-group"

  tags = {
    Name = "${var.cluster_name}-product-service-mysql"
  }
}
