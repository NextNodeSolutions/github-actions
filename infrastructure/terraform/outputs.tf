# Admin server outputs
output "admin_ip" {
  description = "Public IPv4 address of the admin/management VPS"
  value       = module.admin_vps.ipv4_address
}

output "admin_id" {
  description = "ID of the admin/management VPS"
  value       = module.admin_vps.id
}

# Dev worker outputs
output "dev_ip" {
  description = "Public IPv4 address of the development worker VPS"
  value       = module.dev_vps.ipv4_address
}

output "dev_id" {
  description = "ID of the development worker VPS"
  value       = module.dev_vps.id
}

# Prod worker outputs
output "prod_ip" {
  description = "Public IPv4 address of the production worker VPS"
  value       = module.prod_vps.ipv4_address
}

output "prod_id" {
  description = "ID of the production worker VPS"
  value       = module.prod_vps.id
}

# Dokploy dashboard URL (on admin server only)
output "dokploy_url" {
  description = "Dokploy dashboard URL (admin server)"
  value       = "https://${module.admin_vps.ipv4_address}:3000"
}
