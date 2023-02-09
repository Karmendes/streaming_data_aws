// Criando role para o Kinesis
resource "aws_iam_role" "firehose_role" {
  name = "firehose_access_s3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

// Criando policy para a role do kinesis
resource "aws_iam_role_policy" "stream-policy-kinesis" {
    name = "s3-kinesis-glue-policy"
    role = "${aws_iam_role.firehose_role.id}"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":[
        {
            "Effect":"Allow",
            "Action":[
                "s3:*"
            ],
            "Resource":"*"
        },
        {
            "Effect":"Allow",
            "Action":[
                "kinesis:*"
            ],
            "Resource":"*"
        },
        {
            "Effect":"Allow",
            "Action":[
                "glue:*"
            ],
            "Resource":"*"
        }
    ]
}
EOF
}

// Criando role para o Glue
resource "aws_iam_role" "glue_role" {
  name = "glue_access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Effect = "Allow",
        Sid = ""
      }
    ]
  })
}

// Criando policy para role do Glue
resource "aws_iam_role_policy" "stream-policy-glue" {
    name = "awsLogs-policy"
    role = "${aws_iam_role.glue_role.id}"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":[
        {
            "Effect":"Allow",
            "Action":[
                "logs:*"
            ],
            "Resource":"*"
        },
        {
            "Effect":"Allow",
            "Action":[
                "s3:*"
            ],
            "Resource":"*"
        },
        {
            "Effect":"Allow",
            "Action":[
                "glue:*"
            ],
            "Resource":"*"
        }
    ]
}
EOF
}
