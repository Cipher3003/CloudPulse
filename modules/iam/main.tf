resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2_s3_role"
  assume_role_policy = jsondecode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name = "s3_access_policy"
  policy = jsondecode({
    Version = "2012-10-17"
    Statement = {
        Effect = "Allow"
        Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListObject"
        ]
        Resource = [
            "arn:aws:s3:::${var.s3_bucket_name}",
            "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
    }
  })
}

resource "aws_iam_role_policy_attachment" "name" {
  role = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-instance-profile"
  role = aws_iam_role.ec2_s3_role.name
}