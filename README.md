# terraform-azurerm-vnet

Generic, reusable Terraform module for provisioning an Azure Virtual Network with subnets, Network Security Groups, and optional DDoS protection.

## Usage

```hcl
module "vnet" {
  source  = "git::https://github.com/<org>/terraform-azurerm-vnet.git?ref=v1.0.0"

  name                = "vnet-myapp-dev-eus"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = ["10.0.0.0/16"]

  subnets = {
    web = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
    app = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }

  nsg_rules = {
    web = [
      {
        name                   = "AllowHTTP"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        destination_port_range = "80"
      }
    ]
  }

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

## Versioning

This module follows [Semantic Versioning](https://semver.org/). Pin to a specific version using `?ref=v1.0.0`.

## Testing

```bash
terraform init -backend=false
terraform test
```

<!-- BEGIN_TF_DOCS -->

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the virtual network | `string` | n/a | yes |
| resource\_group\_name | Resource group for the VNET | `string` | n/a | yes |
| location | Azure region for the VNET | `string` | n/a | yes |
| address\_space | CIDR address spaces for the VNET | `list(string)` | n/a | yes |
| dns\_servers | Custom DNS servers | `list(string)` | `[]` | no |
| subnets | Map of subnet configurations | `map(object)` | `{}` | no |
| nsg\_rules | Map of subnet NSG security rules | `map(list(object))` | `{}` | no |
| ddos\_protection\_plan\_id | DDoS protection plan ID | `string` | `null` | no |
| tags | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet\_id | The ID of the virtual network |
| vnet\_name | The name of the virtual network |
| vnet\_address\_space | The address space of the virtual network |
| subnet\_ids | Map of subnet name to subnet ID |
| subnet\_address\_prefixes | Map of subnet name to address prefixes |
| nsg\_ids | Map of subnet name to NSG ID |

<!-- END_TF_DOCS -->
