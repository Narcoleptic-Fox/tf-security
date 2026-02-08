/**
 * # Naming Convention Module
 *
 * Generates standardized resource names across AWS and Azure.
 * 
 * ## Pattern
 * `{project}-{environment}-{region_short}-{resource_type}`
 * 
 * Example: `mousing-prod-use1-vpc`
 */

locals {
  # Region short codes
  region_map = {
    # AWS regions
    "us-east-1"      = "use1"
    "us-east-2"      = "use2"
    "us-west-1"      = "usw1"
    "us-west-2"      = "usw2"
    "eu-west-1"      = "euw1"
    "eu-west-2"      = "euw2"
    "eu-central-1"   = "euc1"
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-northeast-1" = "apne1"
    
    # Azure regions
    "eastus"         = "eus"
    "eastus2"        = "eus2"
    "westus"         = "wus"
    "westus2"        = "wus2"
    "westeurope"     = "weu"
    "northeurope"    = "neu"
    "uksouth"        = "uks"
    "ukwest"         = "ukw"
    "australiaeast"  = "aue"
    "southeastasia"  = "sea"
  }

  # Environment short codes
  env_map = {
    "production"  = "prod"
    "prod"        = "prod"
    "staging"     = "stg"
    "stg"         = "stg"
    "development" = "dev"
    "dev"         = "dev"
    "test"        = "tst"
    "tst"         = "tst"
  }

  # Normalize inputs
  project     = lower(replace(var.project, "/[^a-z0-9]/", ""))
  environment = lookup(local.env_map, lower(var.environment), lower(var.environment))
  region      = lookup(local.region_map, lower(var.region), lower(var.region))

  # Base prefix for all resources
  prefix = "${local.project}-${local.environment}-${local.region}"
}
