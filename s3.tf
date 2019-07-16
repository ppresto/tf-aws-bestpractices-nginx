resource "random_id" "my_s3" {
  byte_length = 16
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.name}-${random_id.my_s3.b64_std}"
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

»
