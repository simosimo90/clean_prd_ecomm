
# Dynamo Db table where the services in Lambda write and take the data
# for simplicity I create just 1 table

resource "aws_dynamodb_table" "products_dynamodb" {
  name           = "SelectedProduct"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ProductCategory"
  range_key      = "ProductName"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"


  attribute {
    name = "ProductCategory"
    type = "S"
  }

  attribute {
    name = "ProductName"
    type = "S"
  }

  attribute {
    name = "NumSales"
    type = "N"
  }

  global_secondary_index {
    name               = "ProductNameIndex"
    hash_key           = "ProductName"
    range_key          = "NumSales"
    projection_type    = "INCLUDE"
    non_key_attributes = ["ProductCategory"]
  }

  tags = {
    Name        = "ord-table-1"
    Environment = "production"
  }
}


