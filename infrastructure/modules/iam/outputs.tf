output "github_plan_role_arn" {
  description = "ARN of the GitHub Actions Terraform plan role."
  value       = aws_iam_role.github_plan.arn
}

output "github_deploy_role_arn" {
  description = "ARN of the GitHub Actions production deploy role."
  value       = aws_iam_role.github_deploy.arn
}
