variable "hetzner_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Hetzner datacenter location (from infrastructure/config.json)"
  type        = string
}

variable "dev_server_type" {
  description = "Server type for development VPS (from infrastructure/config.json)"
  type        = string
}

variable "prod_server_type" {
  description = "Server type for production VPS (from infrastructure/config.json)"
  type        = string
}

variable "ssh_keys" {
  description = "List of SSH key IDs to add to servers (optional, for emergency access)"
  type        = list(string)
  default     = []
}
