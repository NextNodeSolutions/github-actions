variable "name" {
  description = "Name of the server"
  type        = string
}

variable "server_type" {
  description = "Hetzner server type (cx23, cx33, etc.)"
  type        = string
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
}

variable "image_id" {
  description = "ID of the image/snapshot to use"
  type        = string
}

variable "labels" {
  description = "Labels to apply to the server"
  type        = map(string)
  default     = {}
}

variable "ssh_keys" {
  description = "List of SSH key IDs"
  type        = list(string)
  default     = []
}

variable "user_data" {
  description = "Cloud-init user data"
  type        = string
  default     = null
}
