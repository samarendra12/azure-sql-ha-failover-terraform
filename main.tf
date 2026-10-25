terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "primary_location" {
  default = "centralindia"
}

variable "secondary_location" {
  default = "southindia"
}

resource "azurerm_resource_group" "db_rg" {
  name     = "rg-enterprise-database-ha"
  location = var.primary_location
}

# Primary SQL Server
resource "azurerm_mssql_server" "primary" {
  name                         = "sql-primary-prod-01"
  resource_group_name          = azurerm_resource_group.db_rg.name
  location                     = var.primary_location
  version                      = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = "P@ssw0rdSecureEnterprise2026!"
  minimum_tls_version          = "1.2"
}

# Secondary SQL Server
resource "azurerm_mssql_server" "secondary" {
  name                         = "sql-secondary-prod-01"
  resource_group_name          = azurerm_resource_group.db_rg.name
  location                     = var.secondary_location
  version                      = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = "P@ssw0rdSecureEnterprise2026!"
  minimum_tls_version          = "1.2"
}

# Database
resource "azurerm_mssql_database" "db" {
  name         = "sqldb-enterprise-app"
  server_id    = azurerm_mssql_server.primary.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb  = 32
  sku_name     = "S1"
  zone_redundant = false
}

# Auto-Failover Group
resource "azurerm_mssql_failover_group" "fog" {
  name      = "fog-enterprise-cluster"
  server_id = azurerm_mssql_server.primary.id
  databases = [azurerm_mssql_database.db.id]

  partner_server {
    server_id = azurerm_mssql_server.secondary.id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
}
