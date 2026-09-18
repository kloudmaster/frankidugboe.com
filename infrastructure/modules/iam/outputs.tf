output "github_plan_role_arn" {
  description = "ARN of the GitHub Actions Terraform plan role."
  value       = aws_iam_role.github_plan.arn
}

output "github_deploy_role_arn" {
  description = "ARN of the GitHub Actions production deploy role."
  value       = aws_iam_role.github_deploy.arn
}

output "contact_exec_role_arn" {
  description = "ARN of the contact Lambda execution role (created in the security plane)."
  value       = aws_iam_role.contact_exec.arn
}
