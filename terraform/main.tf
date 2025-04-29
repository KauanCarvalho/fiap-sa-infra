data "aws_availability_zones" "available" {}

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "fiap-restaurant-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "fiap-restaurant-public-subnet-${count.index}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "fiap-restaurant-igw"
  }
}

resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_nodes_sg" {
  vpc_id      = aws_vpc.this.id
  description = "EKS node group SG"

  ingress {
    description = "Allow EKS control plane to communicate with nodes"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all node-to-node traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "Allow pods from anywhere (optional)"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-eks-nodes-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }

  version = "1.27"

  tags = {
    Environment = "production"
    Project     = var.cluster_name
  }

  lifecycle {
    ignore_changes = [tags, version, kubernetes_network_config]
  }

  depends_on = [
    aws_vpc.this,
    aws_subnet.public
  ]
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = aws_subnet.public[*].id

  ami_type             = "AL2_x86_64"
  capacity_type        = "SPOT"
  disk_size            = 20
  force_update_version = false
  instance_types       = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  labels = {
    role = "nodes-${var.cluster_name}"
  }

  depends_on = [aws_eks_cluster.this]
}

resource "aws_lb" "http" {
  name                             = "fiap-restaurant-lb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.lb_sg.id]
  subnets                          = aws_subnet.public[*].id
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "fiap-restaurant-lb"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "fiap-restaurant-rds-subnet-group"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "fiap-restaurant-rds-subnet-group"
  }
}

resource "aws_db_instance" "rds_mysql_order" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.id
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_name                = var.mysql_order_db_name
  username               = var.mysql_order_db_username
  password               = var.mysql_order_db_password
  skip_final_snapshot    = true
  publicly_accessible    = true

  tags = {
    Name = "fiap-restaurant-rds-mysql-order"
  }

  depends_on = [
    aws_db_subnet_group.rds_subnet_group,
    aws_security_group.rds_sg
  ]
}

resource "aws_db_instance" "rds_mysql_product" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.id
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_name                = var.mysql_product_db_name
  username               = var.mysql_product_db_username
  password               = var.mysql_product_db_password
  skip_final_snapshot    = true
  publicly_accessible    = true

  tags = {
    Name = "fiap-restaurant-rds-mysql-product"
  }

  depends_on = [
    aws_db_subnet_group.rds_subnet_group,
    aws_security_group.rds_sg
  ]
}
