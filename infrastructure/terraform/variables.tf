variable "hetzner_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "nbg1"
}

variable "dev_server_type" {
  description = "Server type for development VPS"
  type        = string
  default     = "cx23"
}

variable "prod_server_type" {
  description = "Server type for production VPS"
  type        = string
  default     = "cx33"
}

variable "ssh_keys" {
  description = "List of SSH key IDs to add to servers (optional, for emergency access)"
  type        = list(string)
  default     = []
}
