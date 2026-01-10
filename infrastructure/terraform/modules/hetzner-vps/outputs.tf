output "id" {
  description = "ID of the server"
  value       = hcloud_server.this.id
}

output "ipv4_address" {
  description = "Public IPv4 address of the server"
  value       = hcloud_server.this.ipv4_address
}

output "ipv6_address" {
  description = "Public IPv6 address of the server"
  value       = hcloud_server.this.ipv6_address
}

output "status" {
  description = "Status of the server"
  value       = hcloud_server.this.status
}
