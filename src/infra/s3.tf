// Criando bucket no S3 
resource "aws_s3_bucket" "s3_lake" {
  bucket = "fake-iot-data"
  acl    = "private"

  tags = {
    Name   = "streaming_data_aws"
  }
}
