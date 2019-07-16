resource "random_string" "my_s3" {
  length  = 16
  special = false
  upper   = false
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.name}-${random_string.my_s3.result}"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags {
    Env = "${var.name}"
  }

  lifecycle_rule {
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

# Zip your src/ folder with all files.
data "archive_file" "zip" {
  type        = "zip"
  output_path = "${path.module}/assets/assets.zip"
  source_dir  = "${path.module}/assets"
}

# Publish your zip on S3.
resource "aws_s3_bucket_object" "content" {
  bucket = "${aws_s3_bucket.bucket.id}"
  key    = "assets.zip"
  source = "${data.archive_file.zip.output_path}"
  etag   = "${md5(file(data.archive_file.zip.output_path))}"
}

output "my_bucket" {
  value = "${aws_s3_bucket.bucket.arn}"
}
