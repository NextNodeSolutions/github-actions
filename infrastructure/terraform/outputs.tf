output "dev_ip" {
  description = "Public IPv4 address of the development VPS"
  value       = module.dev_vps.ipv4_address
}

output "dev_id" {
  description = "ID of the development VPS"
  value       = module.dev_vps.id
}

output "prod_ip" {
  description = "Public IPv4 address of the production VPS"
  value       = module.prod_vps.ipv4_address
}

output "prod_id" {
  description = "ID of the production VPS"
  value       = module.prod_vps.id
}

output "dokploy_dev_url" {
  description = "Dokploy dashboard URL for development"
  value       = "https://${module.dev_vps.ipv4_address}:3000"
}

output "dokploy_prod_url" {
  description = "Dokploy dashboard URL for production"
  value       = "https://${module.prod_vps.ipv4_address}:3000"
}
