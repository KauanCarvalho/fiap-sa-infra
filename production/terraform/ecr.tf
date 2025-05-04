resource "aws_ecr_repository" "fiap_sa_eks_ecr_repository" {
  name = "fiap-sa/eks"

  image_scanning_configuration {
    scan_on_push = true
  }
}
