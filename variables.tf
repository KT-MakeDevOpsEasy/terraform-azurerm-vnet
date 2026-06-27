variable "name" {
  description = "Name of the virtual network"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,62}[a-zA-Z0-9_]$", var.name))
    error_message = "VNET name must be 2-64 characters, start with alphanumeric, end with alphanumeric or underscore."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the VNET will be created"
  type        = string
}

variable "location" {
  description = "Azure region for the VNET"
  type        = string
}

variable "address_space" {
  description = "List of address spaces for the VNET (CIDR notation)"
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space must be provided."
  }
}

variable "dns_servers" {
  description = "Custom DNS servers. Leave empty to use Azure-provided DNS."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Map of subnet name to configuration. Keys are used as subnet names."
  type = map(object({
    address_prefixes                  = list(string)
    service_endpoints                 = optional(list(string), [])
    private_endpoint_network_policies = optional(string, "Enabled")
  }))
  default = {}
}

variable "nsg_rules" {
  description = "Map of subnet name to list of NSG security rules. Creates one NSG per subnet key and associates it."
  type = map(list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string, "*")
    destination_port_range     = optional(string, "*")
    source_address_prefix      = optional(string, "*")
    destination_address_prefix = optional(string, "*")
  })))
  default = {}
}

variable "ddos_protection_plan_id" {
  description = "ID of an existing DDoS protection plan to associate with the VNET. Leave null to disable."
  type        = string
  default     = null
}

variable "enforce_deny_all_inbound" {
  description = "Automatically append a DenyAllInbound rule (priority 4096) to every NSG"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources (ManagedBy=terraform is always added)"
  type        = map(string)
  default     = {}
}
