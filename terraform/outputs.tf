output "health_url" {
  value = "${aws_alb.this.dns_name}/healthcheck"
}

output "ecr_repo" {
  value = "${aws_ecr_repository.this.repository_url}"
}