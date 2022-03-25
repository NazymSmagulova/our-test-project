terraform {
  backend "azurerm" {
    resource_group_name  = "StorageAccount-ResourceGroup"
    storage_account_name = "team2project"
    container_name       = "tfstate"
    key                  = "path/to/my/asg/prod.terraform.tfstate"
    access_key           = "pbdzjjYmnpXTUmYIi/bLxl5qhq+iDbkHXCTFe+UhTwi1UoF1ZvzOszr/KcZFXtkvLPgm+YiyX6NI+AStIDDJsA=="
  }
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}


resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  resource_group_name = "terraform-resources"
  virtual_network_name = "terraform_vnet"
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_linux_virtual_machine_scale_set" "terraform_ss" {
  name                = "terraform_ss"
  resource_group_name = "terraform-resources"
  location = "westus"
  sku                 = "Standard_F2"
  instances           = 1
  admin_username      = "adminuser"
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "terraform"
    primary = true

    ip_configuration {
      name      = "subnet2"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
    }
  }
}
resource "azurerm_traffic_manager_profile" "tm" {
  name                = "tm-profile"
  resource_group_name = "terraform-resources"
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = "tm-profile"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "http"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "terraform" {
  name                = "terraform-endpoint"
  resource_group_name = "terraform-resources"
  profile_id          = azurerm_traffic_manager_profile.tm.id
  weight              = 100
}