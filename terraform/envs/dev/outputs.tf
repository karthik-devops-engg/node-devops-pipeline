output "alb_dns_name" {
  value = module.alb.dns_name
}

output "app_public_ips" {
  value = module.app.public_ips
}

output "monitoring_public_ip" {
  value = module.monitoring.public_ips[0]
}

output "app_sg_id" {
  value = module.security.app_sg_id
}
