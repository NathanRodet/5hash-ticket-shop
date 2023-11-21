# All comments are mode by Github Copilot, this is not ChatGPT
# The resources are configured with tags to allow for easier cost management.

# This resource is used to generate a random prefix for the kubernetes dns prefix.
resource "random_pet" "prefix" {}

# This container registry is used to store the images built by the build pipeline.
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

# This role assignment is used to allow the AKS cluster to pull images from the container registry.
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

# This Kubernetes cluster is used to host the prestashop application.
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.PROJECT_NAME}-${var.ENVIRONMENT}-${var.LOCATION}"
  resource_group_name = var.RESOURCE_GROUP_NAME
  location            = var.LOCATION

  sku_tier   = "Standard"
  dns_prefix = "${random_pet.prefix.id}-k8s"

  default_node_pool {
    name = "default"

    # The same vm_size is used for all environments to prevent unexpected costs. Only the number of nodes is changed.
    vm_size = var.ENVIRONMENT == "prod" ? "Standard_B2s" : var.ENVIRONMENT == "rec" ? "Standard_B2s" : var.ENVIRONMENT == "dev" ? "Standard_B2s" : null

    enable_auto_scaling = true
    # The max and min count is set to 5 for production and rec, and 1 for dev.
    max_count       = var.ENVIRONMENT == "prod" ? 5 : var.ENVIRONMENT == "rec" ? 5 : var.ENVIRONMENT == "dev" ? 1 : null
    min_count       = var.ENVIRONMENT == "prod" ? 2 : var.ENVIRONMENT == "rec" ? 2 : var.ENVIRONMENT == "dev" ? 1 : null
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

  # oms_agent {
  #   log_analytics_workspace_id = azurerm_log_analytics_workspace.aks-log-analytics.id
  # }

  tags = {
    environment = var.ENVIRONMENT
    project     = var.PROJECT_NAME
  }
}

# This log analytics workspace is used to store the logs from the kubernetes cluster and debug.
# resource "azurerm_log_analytics_workspace" "aks-log-analytics" {
#   name                = "log-workplace-${var.PROJECT_NAME}-${var.ENVIRONMENT}-${var.LOCATION}"
#   location            = var.LOCATION
#   resource_group_name = var.RESOURCE_GROUP_NAME
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
# }

# This MySQL Server is used to store the data for the prestashop application.
# The database is configured with a single vCore and 10GB of storage. (for cost reasons)
# The database is configured with auto-growth disabled to prevent unexpected costs.
# The database is configured with a 7 day backup retention period. (default, for cost reasons)
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
  # Because we will not pay a custom domain and a certificate for this project, we will not enable SSL.
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.ENVIRONMENT
    project     = var.PROJECT_NAME
  }
}

# This MySQL Database is used to store the data for the prestashop application.
resource "azurerm_mysql_database" "mysql_database" {
  name                = "prestashopdb${var.ENVIRONMENT}"
  resource_group_name = var.RESOURCE_GROUP_NAME
  server_name         = azurerm_mysql_server.mysql_server.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

# Allow all internal azure services to access the MySQL Database. Source : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/sql_firewall_rule
resource "azurerm_mysql_firewall_rule" "firewall_rule_allow_azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = var.RESOURCE_GROUP_NAME
  server_name         = azurerm_mysql_server.mysql_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
