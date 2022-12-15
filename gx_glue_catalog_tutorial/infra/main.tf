locals {
  bucket_name    = "${var.bucket_name}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  table_location = "${var.datalake_prefix}/${var.database_name}/${var.table_name}"
}

###################
## S3 Buckets    ##
###################
resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = true
  }

  depends_on = [
    aws_s3_bucket.this
  ]
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket.this
  ]
}

# Upload data to s3 bucket
resource "aws_s3_object_copy" "this" {
  for_each = toset(var.batch_dates)

  bucket = aws_s3_bucket.this.id
  key    = "${local.table_location}/year=${split("-", each.value)[0]}/month=${split("-", each.value)[1]}/yellow_tripdata_${each.value}.parquet"
  source = "nyc-tlc/trip data/yellow_tripdata_${each.value}.parquet"

  depends_on = [
    aws_s3_bucket.this
  ]
}

###################
## IAM Roles     ##
###################
resource "aws_iam_policy" "this" {
  name        = "${var.glue_role_name}-Policy"
  path        = "/"
  description = "Great Expectations with AWS Glue Data Catalog Demo Role Policy"
  tags        = var.tags

  # Terraform"s "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement : [
      {
        "Sid" : "GrantS3Permissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:*",
        ],
        "Resource" : [
          "${aws_s3_bucket.this.arn}/*",
          aws_s3_bucket.this.arn
        ]
      },
      {
        "Sid" : "GrantGlueNotebookAccess",
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.glue_role_name}"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.this
  ]
}

resource "aws_iam_role" "this" {
  name                = var.glue_role_name
  managed_policy_arns = [data.aws_iam_policy.AWSGlueServiceRole.arn, aws_iam_policy.this.arn]
  tags                = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = [
            "glue.amazonaws.com"
          ]
        }
      }
    ]
  })

  depends_on = [aws_iam_policy.this]
}


###################
## Glue Catalog  ##
###################

resource "aws_glue_catalog_database" "this" {
  name = var.database_name

  create_table_default_permission {
    permissions = ["ALL"]

    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }
}

resource "aws_glue_catalog_table" "this" {
  name          = var.table_name
  database_name = aws_glue_catalog_database.this.name
  description   = "Table for NYC Trip Data"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"       = "TRUE"
    "classification" = "parquet"
  }

  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.this.id}/${local.table_location}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    compressed    = false

    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "vendorid"
      type = "bigint"
    }
    columns {
      name = "tpep_pickup_datetime"
      type = "timestamp"
    }
    columns {
      name = "tpep_dropoff_datetime"
      type = "timestamp"
    }
    columns {
      name = "passenger_count"
      type = "double"
    }
    columns {
      name = "trip_distance"
      type = "double"
    }
    columns {
      name = "ratecodeid"
      type = "double"
    }
    columns {
      name = "store_and_fwd_flag"
      type = "string"
    }
    columns {
      name = "pulocationid"
      type = "bigint"
    }
    columns {
      name = "dolocationid"
      type = "bigint"
    }
    columns {
      name = "payment_type"
      type = "bigint"
    }
    columns {
      name = "fare_amount"
      type = "double"
    }
    columns {
      name = "extra"
      type = "double"
    }
    columns {
      name = "mta_tax"
      type = "double"
    }
    columns {
      name = "tip_amount"
      type = "double"
    }
    columns {
      name = "tolls_amount"
      type = "double"
    }
    columns {
      name = "improvement_surcharge"
      type = "double"
    }
    columns {
      name = "total_amount"
      type = "double"
    }
    columns {
      name = "congestion_surcharge"
      type = "double"
    }
    columns {
      name = "airport_fee"
      type = "double"
    }
  }
}

resource "aws_glue_partition" "this" {
  for_each = toset(var.batch_dates)

  database_name    = aws_glue_catalog_database.this.name
  table_name       = aws_glue_catalog_table.this.name
  partition_values = [split("-", each.value)[0], split("-", each.value)[1]]


  storage_descriptor {
    location      = "s3://${aws_s3_bucket.this.id}/${local.table_location}/year=${split("-", each.value)[0]}/month=${split("-", each.value)[1]}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    compressed    = false

    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "vendorid"
      type = "bigint"
    }
    columns {
      name = "tpep_pickup_datetime"
      type = "timestamp"
    }
    columns {
      name = "tpep_dropoff_datetime"
      type = "timestamp"
    }
    columns {
      name = "passenger_count"
      type = "double"
    }
    columns {
      name = "trip_distance"
      type = "double"
    }
    columns {
      name = "ratecodeid"
      type = "double"
    }
    columns {
      name = "store_and_fwd_flag"
      type = "string"
    }
    columns {
      name = "pulocationid"
      type = "bigint"
    }
    columns {
      name = "dolocationid"
      type = "bigint"
    }
    columns {
      name = "payment_type"
      type = "bigint"
    }
    columns {
      name = "fare_amount"
      type = "double"
    }
    columns {
      name = "extra"
      type = "double"
    }
    columns {
      name = "mta_tax"
      type = "double"
    }
    columns {
      name = "tip_amount"
      type = "double"
    }
    columns {
      name = "tolls_amount"
      type = "double"
    }
    columns {
      name = "improvement_surcharge"
      type = "double"
    }
    columns {
      name = "total_amount"
      type = "double"
    }
    columns {
      name = "congestion_surcharge"
      type = "double"
    }
    columns {
      name = "airport_fee"
      type = "double"
    }
  }
}
