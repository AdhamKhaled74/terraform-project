output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "app_sg_id" {
  value = aws_security_group.app.id
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "scale_out_policy_arn" {
  value = aws_autoscaling_policy.scale_out.arn
}
