output "bucketName" {
  value = aws_s3_bucket.this.id
}

output "glueRoleArn" {
  value = aws_iam_role.this.arn
}

output "databaseName" {
  value = aws_glue_catalog_database.this.id
}

output "tableName" {
  value = aws_glue_catalog_table.this.id
}