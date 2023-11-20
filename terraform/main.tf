resource "random_pet" "prefix" {}

resource "azurerm_container_registry" "acr" {
  name                = "acr${var.PROJECT_NAME}${var.ENVIRONMENT}${var.LOCATION}"
  resource_group_name = var.RESOURCE_GROUP_NAME
  location            = var.LOCATION
  sku                 = "Basic"
  admin_enabled       = false

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.ENVIRONMENT
    project     = var.PROJECT_NAME
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_container_registry.acr,
    azurerm_kubernetes_cluster.aks
  ]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.PROJECT_NAME}-${var.ENVIRONMENT}-${var.LOCATION}"
  resource_group_name = var.RESOURCE_GROUP_NAME
  location            = var.LOCATION

  sku_tier   = "Standard"
  dns_prefix = "${random_pet.prefix.id}-k8s"

  default_node_pool {
    name = "default"

    vm_size = var.ENVIRONMENT == "prod" ? "Standard_B2s" : var.ENVIRONMENT == "rec" ? "Standard_B2s" : var.ENVIRONMENT == "dev" ? "Standard_B2s" : null

    enable_auto_scaling = true
    # Match the client prerequisites
    max_count       = var.ENVIRONMENT == "prod" ? 3 : var.ENVIRONMENT == "rec" ? 3 : var.ENVIRONMENT == "dev" ? 1 : null
    min_count       = var.ENVIRONMENT == "prod" ? 3 : var.ENVIRONMENT == "rec" ? 3 : var.ENVIRONMENT == "dev" ? 1 : null
    max_pods        = var.ENVIRONMENT == "prod" ? 60 : var.ENVIRONMENT == "rec" ? 60 : var.ENVIRONMENT == "dev" ? 60 : null
    os_disk_size_gb = "30"
  }

  auto_scaler_profile {
    scan_interval                    = "10s"
    balance_similar_node_groups      = false
    expander                         = var.ENVIRONMENT == "prod" ? "least-waste" : var.ENVIRONMENT == "rec" ? "least-waste" : var.ENVIRONMENT == "dev" ? "least-waste" : null
    scale_down_utilization_threshold = "0.5"
    scale_down_delay_after_add       = "3m"
    scale_down_unneeded              = "3m"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.ENVIRONMENT
    project     = var.PROJECT_NAME
  }
  
}

resource "azurerm_mysql_server" "mysql_server" {
  name                = "sqlserver-${var.PROJECT_NAME}-${var.ENVIRONMENT}-${var.LOCATION}"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP_NAME

  administrator_login          = var.MYSQL_ADMIN_LOGIN
  administrator_login_password = var.MYSQL_ADMIN_PASSWORD

  sku_name   = var.ENVIRONMENT == "prod" ? "GP_Gen5_4" : var.ENVIRONMENT == "rec" ? "B_Gen5_2" : var.ENVIRONMENT == "dev" ? "B_Gen5_2" : null
  storage_mb = 10240
  version    = "5.7"

  auto_grow_enabled                 = false # Free tier.
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}
