# EKS CLuster Definition

resource "aws_eks_cluster" "eks-cluster" {
  name     = "Eks-cluster"
  role_arn = aws_iam_role.eks-cluster-role.arn


  vpc_config {
    subnet_ids         = ["subnet-009417083391ee6b9", "subnet-06b380d6079a1d08a"]
    security_group_ids = ["sg-0ce741169531fa6b0"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eksnoderole-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eksnoderole-AmazonEKSVPCResourceController,
  ]
}


output "endpoint" {
  value = aws_eks_cluster.eks-cluster.endpoint
}

# output "node_group_ids" {
#   value = aws_eks_node_group.eksnode.id
# }







# IAM Role for EKS Cluster

resource "aws_iam_role" "eksclusterrole" {
  name = "eksnodegroup"

  assume_role_policy = <<POLICY
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
POLICY
}

resource "aws_iam_role_policy_attachment" "eksnoderole-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eksnoderole-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster-role.name
}






# Enabling IAM Role for Service Account

data "tls_certificate" "ekstls" {
  url = aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eksopidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.ekstls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "eksdoc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eksopidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eksopidc.arn]
      type        = "Federated"
    }
  }
}
