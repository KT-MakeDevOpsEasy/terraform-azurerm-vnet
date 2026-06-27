locals {
  required_tags = {
    ManagedBy = "terraform"
  }

  merged_tags = merge(var.tags, local.required_tags)

  default_nsg_deny_rule = {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  nsg_rules_with_deny = {
    for subnet_key, rules in var.nsg_rules : subnet_key => concat(
      rules,
      [local.default_nsg_deny_rule]
    )
  }

  effective_nsg_rules = var.enforce_deny_all_inbound ? local.nsg_rules_with_deny : var.nsg_rules

  nsg_rules_flat = flatten([
    for nsg_key, rules in local.effective_nsg_rules : [
      for rule in rules : merge(rule, { nsg_key = nsg_key })
    ]
  ])
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = length(var.dns_servers) > 0 ? var.dns_servers : null
  tags                = local.merged_tags

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  name                              = each.key
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = each.value.address_prefixes
  service_endpoints                 = length(each.value.service_endpoints) > 0 ? each.value.service_endpoints : null
  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  lifecycle {
    ignore_changes = [
      delegation,
      service_endpoint_policy_ids,
    ]
  }
}

resource "azurerm_network_security_group" "nsg" {
  for_each = local.effective_nsg_rules

  name                = "nsg-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.merged_tags
}

resource "azurerm_network_security_rule" "rule" {
  for_each = {
    for rule in local.nsg_rules_flat : "${rule.nsg_key}-${rule.name}" => rule
  }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[each.value.nsg_key].name
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = local.effective_nsg_rules

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}
