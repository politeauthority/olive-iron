# Eks
# Create the EKS cluster and all its supporting resources.
#
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

resource "aws_eks_cluster" "cluster_one" {
    name     = "${var.project}"
    role_arn = aws_iam_role.eks-iam-role.arn
    version  = "1.27"

    vpc_config {
        subnet_ids = [
            aws_subnet.public_subnet[0].id,
            aws_subnet.public_subnet[1].id,
            aws_subnet.public_subnet[2].id,
            aws_subnet.private_subnet[0].id,
            aws_subnet.private_subnet[1].id,
            aws_subnet.private_subnet[2].id
        ]
    }
    depends_on = [
        aws_iam_role.eks-iam-role,
        aws_subnet.public_subnet,
        aws_subnet.private_subnet
    ]
}

resource "aws_iam_role" "workernodes" {
    name = "${var.project}-eks-node-group"
 
    assume_role_policy = jsonencode({
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }]
        Version = "2012-10-17"
    })
    depends_on = [
        aws_eks_cluster.cluster_one,
    ]
}
 
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.workernodes.name
}
 
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = aws_iam_role.workernodes.name
}
 
resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
    policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
    role       = aws_iam_role.workernodes.name
}
 
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role       = aws_iam_role.workernodes.name
}

resource "aws_eks_node_group" "worker-node-group" {
    cluster_name    = "${var.project}"
    node_group_name = "${var.project}-workernodes"
    node_role_arn   = aws_iam_role.workernodes.arn
    subnet_ids      = [
        aws_subnet.private_subnet[0].id, 
        aws_subnet.private_subnet[1].id,
        aws_subnet.private_subnet[2].id,
        aws_subnet.public_subnet[0].id,
        aws_subnet.public_subnet[1].id,
        aws_subnet.public_subnet[2].id,
    ]
    instance_types  = ["m5.large"]
 
    scaling_config {
        desired_size = 3
        max_size     = 3
        min_size     = 1
    }
 
  depends_on = [
        aws_eks_cluster.cluster_one,
        aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
        aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}
