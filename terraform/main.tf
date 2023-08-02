# Main
#
terraform {
 required_providers {
  aws = {
   source = "hashicorp/aws"
  }
 }
}

resource "aws_iam_role" "eks-iam-role" {
    name = "eks-iam-role"
    path = "/"
    assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role    = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role    = aws_iam_role.eks-iam-role.name
}

# resource "aws_eks_cluster" "cluster-one" {
#     name = "cluster-one"
#     role_arn = aws_iam_role.eks-iam-role.arn

#     vpc_config {
#         subnet_ids = [var.public_subnets.id, aws_subnet.private_subnets.id]
#     }
#     depends_on = [
#         aws_iam_role.eks-iam-role,
#         aws_subnet.public_subnets,
#         aws_subnet.private_subnets
#     ]
# }
