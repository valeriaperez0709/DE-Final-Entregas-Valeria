output "bucket_name" {
  value = aws_s3_bucket.entregas.bucket
}

output "glue_database" {
  value = aws_glue_catalog_database.entregas.name
}

output "glue_table" {
  value = aws_glue_catalog_table.entregas.name
}

output "athena_workgroup" {
  value = aws_athena_workgroup.entregas.name
}
