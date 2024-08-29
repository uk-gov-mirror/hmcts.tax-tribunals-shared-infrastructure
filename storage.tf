locals {
  standard_subnets = [
    data.azurerm_subnet.jenkins_subnet.id,
    data.azurerm_subnet.jenkins_aks_00.id,
    data.azurerm_subnet.jenkins_aks_01.id,
    data.azurerm_subnet.cft_aks_00_subnet.id,
    data.azurerm_subnet.cft_aks_01_subnet.id
  ]

  preview_subnets   = var.env == "aat" ? [data.azurerm_subnet.preview_aks_00_subnet.id, data.azurerm_subnet.preview_aks_01_subnet.id] : []
  perftest_subnets  = var.env == "perftest" ? [data.azurerm_subnet.perftest_mgmt_subnet.id] : []
  all_valid_subnets = concat(local.standard_subnets, local.preview_subnets, local.perftest_subnets)
}

module "storage-account" {
  source               = "git@github.com:hmcts/cnp-module-storage-account?ref=master"
  env                  = var.env
  storage_account_name = replace("${var.product}sa${var.env}", "-", "")
  resource_group_name  = azurerm_resource_group.rg.name
  location             = var.location
  account_kind         = var.sa_account_kind

  account_tier             = var.sa_account_tier
  account_replication_type = var.sa_account_replication_type
  common_tags              = var.common_tags

  sa_subnets = local.all_valid_subnets

  containers = [
    {
      name        = "public"
      access_type = "private"
    },
    {
      name        = "private"
      access_type = "private"
    }
  ]
}


resource "azurerm_key_vault_secret" "tt_store_storageaccount_id" {
  depends_on   = [module.tt-key-vault]
  name         = "tt-storage-account-id"
  value        = module.storage-account.storageaccount_id
  key_vault_id = module.tt-key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "tt-storageaccount_primary_access_key" {
  depends_on   = [module.tt-key-vault]
  name         = "tt-storage-account-primary-access-key"
  value        = module.storage-account.storageaccount_primary_access_key
  key_vault_id = module.tt-key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "tt-storageaccount_secondary_access_key" {
  depends_on   = [module.tt-key-vault]
  name         = "tt-storage-account-secondary-access-key"
  value        = module.storage-account.storageaccount_secondary_access_key
  key_vault_id = module.tt-key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "tt-storageaccount_primary_connection_string" {
  depends_on   = [module.tt-key-vault]
  name         = "tt-storage-account-primary-connection-string"
  value        = module.storage-account.storageaccount_primary_connection_string
  key_vault_id = module.tt-key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "tt-storageaccount_secondary_connection_string" {
  depends_on   = [module.tt-key-vault]
  name         = "tt-storage-account-secondary-connection-string"
  value        = module.storage-account.storageaccount_secondary_connection_string
  key_vault_id = module.tt-key-vault.key_vault_id
}

output "tt-storage-account_name" {
  value = module.storage-account.storageaccount_name
}