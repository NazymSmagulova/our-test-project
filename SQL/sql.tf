provider "azurerm" {
  features {}
}


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
}


data "terraform_remote_state" "main" {
  backend = "azurerm"
  config = {
    resource_group_name  = "StorageAccount-ResourceGroup"
    storage_account_name = "team2project"
    container_name       = "tfstate"
    key                  = "path/to/my/key/prod.terraform.tfstate"
    access_key           = "pbdzjjYmnpXTUmYIi/bLxl5qhq+iDbkHXCTFe+UhTwi1UoF1ZvzOszr/KcZFXtkvLPgm+YiyX6NI+AStIDDJsA=="
  }
}

#output "vnet_info" {
# value = data.terraform_remote_state.main.outputs.*
#}



resource "azurerm_mysql_server" "terraform" {
  name                = "terraform-mysqlserver"
  location            = "westus"
  resource_group_name = data.terraform_remote_state.main.outputs.resource_group_name

  administrator_login          = "mysqladmin"  
  administrator_login_password = "H@Sh1CoR3!"

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                = true
  backup_retention_days            = 7
  geo_redundant_backup_enabled     = true
  public_network_access_enabled    = false
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
}

resource "azurerm_mysql_database" "wordpress" {
  name                = "wordpressdb"
  resource_group_name = data.terraform_remote_state.main.outputs.resource_group_name
  server_name         = azurerm_mysql_server.example.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

output "fqdn" {
  value = azurerm_mysql_server.terraform.fqdn
}


# mysql -h endpoint_get_from-console     -u  username@url_from_console   -p password
# create database wordpress; 
# show databases; 
# take a snashot, send the picture to team2  with credentials
#When sql created, it will give username@url