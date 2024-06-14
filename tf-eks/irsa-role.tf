module "load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}

module "external_dns_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                     = "external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${var.hosted_zone_id}"]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = local.tags
}

module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "ebs-csi-switch-ljh-test"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "amazon_managed_service_prometheus_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                                       = "${local.name}-amazon-managed-service-prometheus"
  attach_amazon_managed_service_prometheus_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["monitoring:amp-ingest"]
    }
  }

  tags = local.tags
}


# module "iam_policy_app" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   name    = "ljhAppS3AccessPolicy"
#   path    = "/"
#   description = "App S3 access policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           "arn:aws:s3:::ljh-ladyhapburn-image",
#           "arn:aws:s3:::ljh-ladyhapburn-image/*"
#         ]
#       }
#     ]
#   })
# }

resource "aws_iam_policy" "s3_policy" {
  name        = "${local.name}-s3-access-policy"
  description = "IAM policy for S3 access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "MountpointFullBucketAccess",
        Effect = "Allow",
        Action = [
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::ljh-ladyhapburn-image"
        ],
      },
      {
        Sid    = "MountpointFullObjectAccess",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
        ],
        Resource = [
          "arn:aws:s3:::ljh-ladyhapburn-image/*"
        ],
      },
    ],
  })
}

resource "aws_iam_role" "s3_role" {
  name = "${local.name}-s3-csi-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "${replace(module.eks.oidc_provider, "https://", "")}:sub" = "system:serviceaccount:kube-system:s3-csi-*",
            "${replace(module.eks.oidc_provider, "https://", "")}:aud" = "sts.amazonaws.com",
          },
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "s3_role_attachment" {
  policy_arn = aws_iam_policy.s3_policy.arn
  role       = aws_iam_role.s3_role.name
}


resource "aws_eks_addon" "s3_csi" {
  cluster_name      = local.name
  addon_name        = "aws-mountpoint-s3-csi-driver"
  addon_version     = "v1.5.1-eksbuild.1"
  resolve_conflicts = "OVERWRITE"

  service_account_role_arn = aws_iam_role.s3_role.arn
}

# module "mountpoint_s3_csi_irsa_role" {
#   source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

#   role_name                       = "mountpoint-s3-csi"
#   attach_mountpoint_s3_csi_policy = true
#   mountpoint_s3_csi_bucket_arns   = ["arn:aws:s3:::ljh-ladyhapburn-image"]
#   mountpoint_s3_csi_path_arns     = ["arn:aws:s3:::ljh-ladyhapburn-image/*"]
#   # mountpoint_s3_csi_path_arns     = ["arn:aws:s3:::ljh-ladyhapburn-image/example/*"]

#   oidc_providers = {
#     ex = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:s3-csi-driver-sa"]
#     }
#   }

#   tags = local.tags
# }

# resource "aws_eks_addon" "s3_csi" {
#   cluster_name      = local.name
#   addon_name        = "aws-mountpoint-s3-csi-driver"
#   addon_version     = "v1.5.1-eksbuild.1"
#   resolve_conflicts = "OVERWRITE"

#   service_account_role_arn = module.mountpoint_s3_csi_irsa_role.iam_role_arn
# }

# module "iam_policy" {
#   source = "terraform-aws-modules/iam/aws//modules/iam-policy"

#   name        = "ljh-amp-eks-policy"
#   path        = "/"
#   description = "s3 admin policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:*",
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# module "iam_eks_role" {
#   source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   role_name = "ljh-amp-role"

#   role_policy_arns = {
#     policy = module.iam_policy.arn
#   }

#   oidc_providers = {
#     ex = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:ljh-s3-admin-staging"]
#     }
#     # one = {
#     #   provider_arn               = "arn:aws:iam::012345678901:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/5C54DDF35ER19312844C7333374CC09D"
#     #   namespace_service_accounts = ["default:my-app-staging", "canary:my-app-staging"]
#     # }
#     # two = {
#     #   provider_arn               = "arn:aws:iam::012345678901:oidc-provider/oidc.eks.ap-southeast-1.amazonaws.com/id/5C54DDF35ER54476848E7333374FF09G"
#     #   namespace_service_accounts = ["default:my-app-staging"]
#     # }
#   }
# }