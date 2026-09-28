output "access_analyzer_arn" {
  description = "ARN of the IAM Access Analyzer."
  value       = aws_accessanalyzer_analyzer.this.arn
}
