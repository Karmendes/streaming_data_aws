

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
    type = "integer"
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
    name = "id_device"
    type = "integer"
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
resource "aws_iam_role_policy" "firehose-stream-policy" {
    name = "fire-stream-policy-watchmen"
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
          parameter_value = "{id_device:.id_device}"

        }
    }
    }

      # Example prefix using partitionKeyFromQuery, applicable to JQ processor
        prefix              = "data/!{partitionKeyFromQuery:id_device}/"
        error_output_prefix = "errors/"
    }
    
}