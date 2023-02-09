

// Configurando Provider
provider aws {
      region = "us-east-1"
      version = "~> 4.0"
}

// Criando bucket no S3 
resource "aws_s3_bucket" "s3_lake" {
  bucket = "fake-iot-data"
  acl    = "private"

  tags = {
    Name   = "streaming_data_aws"
  }
}

// Criando Database no glue
resource "aws_glue_catalog_database" "aws_glue_catalog_database" {
  name = "db_iot_fake_data"
}

// Criando tabela no glue
resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = "tb_iot_fake_data"
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name
  storage_descriptor {
    columns{
    name = "temperature"
    type = "int"
  }

   columns{
    name = "cpu"
    type = "float"
  }
   columns{
    name = "ram"
    type = "float"
  }
   columns{
    name = "hd"
    type = "float"
  }
   columns{
    name = "timestamp"
    type = "string"
  }
  columns{
    name = "timestamp_sent"
    type = "string"
  }
  columns{
    name = "id_device"
    type = "int"
  }  
}
  

}


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



resource "aws_glue_crawler" "crawler_iot_data" {
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name
  name          = "crawler_iot_data"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.s3_lake.bucket}"
  }
}

// Criando stream de entrega
resource "aws_kinesis_firehose_delivery_stream" "stream_aws" {
  name        = "stream_fake_iot"
  destination = "extended_s3"
  depends_on = [
    aws_s3_bucket.s3_lake,
    aws_glue_catalog_database.aws_glue_catalog_database,
    aws_glue_catalog_table.aws_glue_catalog_table
  ]


   tags = {
    Name        = "streaming_data_aws"
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.s3_lake.arn

    buffer_size = 128
    buffer_interval = 300
      
    dynamic_partitioning_configuration {
        enabled = true
    }
    data_format_conversion_configuration {
        input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_database.aws_glue_catalog_database.name
        role_arn      = "${aws_iam_role.firehose_role.arn}"
        table_name    = aws_glue_catalog_table.aws_glue_catalog_table.name
      }
    }
    processing_configuration {
        enabled = true
        processors {
          type = "MetadataExtraction"
          parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
          parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{timestamp_sent:.timestamp_sent}"

        }
    }
    }

      # Example prefix using partitionKeyFromQuery, applicable to JQ processor
        prefix              = "data/!{partitionKeyFromQuery:timestamp_sent}/"
        error_output_prefix = "errors/"
    }
    
}