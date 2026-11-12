terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Bucket privado para datos y resultados
resource "aws_s3_bucket" "entregas" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "privado" {
  bucket = aws_s3_bucket.entregas.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Base de datos en Glue Data Catalog
resource "aws_glue_catalog_database" "entregas" {
  name = "db_entregas"
}

# Tabla externa para leer los CSV
resource "aws_glue_catalog_table" "entregas" {
  name          = "entregas"
  database_name = aws_glue_catalog_database.entregas.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification"                 = "csv"
    "skip.header.line.count"         = "1"
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = "2026-10-01,2026-10-03"
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"
    "storage.location.template"      = "s3://${aws_s3_bucket.entregas.bucket}/entregas/fecha=$${fecha}/"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.entregas.bucket}/entregas/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    columns {
      name = "id_envio"
      type = "string"
    }

    columns {
      name = "ciudad"
      type = "string"
    }

    columns {
      name = "transportadora"
      type = "string"
    }

    columns {
      name = "estado"
      type = "string"
    }

    columns {
      name = "duracion_minutos"
      type = "int"
    }
  }

  partition_keys {
    name = "fecha"
    type = "string"
  }
}

# Workgroup de Athena
resource "aws_athena_workgroup" "entregas" {
  name  = "wg_entregas"
  state = "ENABLED"

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.entregas.bucket}/resultados-athena/"
    }
  }
}
