

variable "stage_name" {
	type = string
	description = "The AWS environment to deploy into"
}

provider "aws" {
    region = "ap-northeast-1"
}

locals {
  layer_name = "dep_layer"
  layer_payload = "./dep_layer.zip"
  name = "etl-${var.stage_name}"
}

resource "aws_iam_role" "etl_role" {
	name = local.name
	assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "datapipeline.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow"
    }

  ]
}
EOF
}

resource "aws_iam_role_policy" "etl_role" {
  name = "${local.name}-def"
  role = aws_iam_role.etl_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "datapipeline:DescribeObjects",
                "datapipeline:EvaluateExpression",
                "dynamodb:BatchGetItem",
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:UpdateTable",
                "s3:CreateBucket",
                "s3:DeleteObject",
                "s3:Get*",
                "s3:List*",
                "s3:Put*",
                "sdb:BatchPutAttributes",
                "sdb:Select*",
                "sns:GetTopicAttributes",
                "sns:ListTopics",
                "sns:Publish",
                "sns:Subscribe",
                "sns:Unsubscribe",
                "sts:AssumeRole",
                
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents",
                "s3:*",
                "datapipeline:*",
                "iam:GetInstanceProfile",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListRolePolicies",
                "iam:ListInstanceProfiles",
                "iam:PassRole",

                "cloudwatch:*",
                "dynamodb:*",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CancelSpotInstanceRequests",
                "ec2:CreateSecurityGroup",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:Describe*",
                "ec2:ModifyImageAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:RequestSpotInstances",
                "ec2:RunInstances",
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:DeleteSecurityGroup",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DetachNetworkInterface",
                "elasticmapreduce:*",
                "rds:DescribeDBInstances",
                "rds:DescribeDBSecurityGroups",
                "redshift:DescribeClusters",
                "redshift:DescribeClusterSecurityGroups",
                "sdb:*",
                "sns:*",
                "sqs:*"
            ],
            "Resource": "*"
        },
        {
            "Action": "iam:PassRole",
            "Effect": "Allow",
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}




resource "aws_iam_role" "etl_test_role" {
  name = "etl_test_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }

  ]
}
EOF
}


resource "aws_iam_role_policy" "etl_test_role" {
  name = "etl_test_role_def"
  role = aws_iam_role.etl_test_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:*",
                "datapipeline:*",
                "dynamodb:*",
                "ec2:Describe*",
                "elasticmapreduce:AddJobFlowSteps",
                "elasticmapreduce:Describe*",
                "elasticmapreduce:ListInstance*",
                "elasticmapreduce:ModifyInstanceGroups",
                "rds:Describe*",
                "redshift:DescribeClusters",
                "redshift:DescribeClusterSecurityGroups",
                "s3:*",
                "sdb:*",
                "sns:*",
                "sqs:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}





resource "aws_s3_bucket" "glue_scripts" {
  // these need to be globaly unique across *all* of S3
  bucket = "pavel010-glue-scripts-${var.stage_name}"
  acl    = "private"
}

resource "aws_s3_bucket_object" "glue_scripts_code" {
  bucket = aws_s3_bucket.glue_scripts.bucket
  key    = "etl.py"
  source = "etl.py"
}

resource "aws_glue_crawler" "glue_crawler" {
  database_name = "glue_crawler-${var.stage_name}"
  name          = "glue_crawler"
  role          = aws_iam_role.etl_role.arn

  dynamodb_target {
    path = "wtb_api_events-${var.stage_name}"
  }
}

resource "aws_glue_job" "glue_etl_job" {
  name     = "glue_etl_job"
  role_arn = aws_iam_role.etl_role.arn
  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/etl.py"
  }
}

resource "aws_glue_trigger" "etl_trigger" {
  name = "etl_trigger"
  type = "ON_DEMAND"
  actions {
    job_name = aws_glue_job.glue_etl_job.name
  }
}




