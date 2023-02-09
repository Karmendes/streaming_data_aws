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
resource "aws_glue_crawler" "crawler_iot_data" {
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name
  name          = "crawler_iot_data"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.s3_lake.bucket}"
  }
}