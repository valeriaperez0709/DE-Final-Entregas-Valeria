variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nombre unico del bucket S3"
  type        = string
}
