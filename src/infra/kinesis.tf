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