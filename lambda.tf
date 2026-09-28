data "archive_file" "scan_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/scan.py"
  output_path = "${path.module}/scan.zip"
}


