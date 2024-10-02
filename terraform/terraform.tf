resource "aws_s3_bucket" "terraform_state" {
  bucket = "canoe-tfstates-bucket-${random_string.random.result}"
     
  lifecycle {
    prevent_destroy = false
  }
}

resource "random_string" "random" {
  length           = 8
  upper            = false
  special          = false
}


resource "aws_s3_bucket_versioning" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id

    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}