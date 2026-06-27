mock_provider "azurerm" {}

variables {
  name                = "vnet-test-dev-eus"
  resource_group_name = "rg-test"
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]
  subnets = {
    web = {
      address_prefixes = ["10.0.1.0/24"]
    }
    app = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
  }
  nsg_rules = {
    web = [
      {
        name                       = "AllowHTTP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  }
  tags = {
    Environment = "test"
    Project     = "unit-test"
  }
}

run "creates_vnet_with_correct_attributes" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.vnet.name == "vnet-test-dev-eus"
    error_message = "VNET name mismatch"
  }

  assert {
    condition     = azurerm_virtual_network.vnet.location == "eastus"
    error_message = "VNET location mismatch"
  }

  assert {
    condition     = tolist(azurerm_virtual_network.vnet.address_space) == tolist(["10.0.0.0/16"])
    error_message = "VNET address space mismatch"
  }
}

run "creates_expected_subnets" {
  command = plan

  assert {
    condition     = azurerm_subnet.subnet["web"].name == "web"
    error_message = "Web subnet not created"
  }

  assert {
    condition     = azurerm_subnet.subnet["app"].name == "app"
    error_message = "App subnet not created"
  }

  assert {
    condition     = tolist(azurerm_subnet.subnet["web"].address_prefixes) == tolist(["10.0.1.0/24"])
    error_message = "Web subnet address prefix mismatch"
  }
}

run "creates_nsg_for_web_subnet" {
  command = plan

  assert {
    condition     = azurerm_network_security_group.nsg["web"].name == "nsg-web"
    error_message = "NSG for web subnet not created"
  }

  assert {
    condition     = azurerm_network_security_rule.rule["web-AllowHTTP"].name == "AllowHTTP"
    error_message = "AllowHTTP rule not created"
  }

  assert {
    condition     = azurerm_network_security_rule.rule["web-AllowHTTP"].destination_port_range == "80"
    error_message = "AllowHTTP rule port mismatch"
  }
}

run "applies_tags_to_all_resources" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.vnet.tags["Environment"] == "test"
    error_message = "VNET missing Environment tag"
  }

  assert {
    condition     = azurerm_network_security_group.nsg["web"].tags["Project"] == "unit-test"
    error_message = "NSG missing Project tag"
  }
}

run "no_ddos_plan_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_virtual_network.vnet.ddos_protection_plan) == 0
    error_message = "DDoS protection plan should not be set by default"
  }
}

run "no_nsg_when_no_rules" {
  command = plan

  variables {
    nsg_rules = {}
  }

  assert {
    condition     = length(azurerm_network_security_group.nsg) == 0
    error_message = "No NSGs should be created when nsg_rules is empty"
  }
}

run "validates_vnet_name" {
  command = plan

  variables {
    name = "-invalid-name"
  }

  expect_failures = [var.name]
}
