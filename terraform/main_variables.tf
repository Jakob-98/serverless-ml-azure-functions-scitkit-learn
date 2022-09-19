variable "resourcegroup_name" {
  type        = string
  description = "The name of the resourcegroup to deploy to."
}

variable "serverless_ml_functionapp_sku_tier" {
  type        = string
  description = "The SKU tier for the Azure Function App. Valid values: Basic, Standard, Dynamic"
  default     = "Dynamic"
}

variable "serverless_ml_functionapp_sku_size" {
  type        = string
  description = "The SKU size for the Azure Function App. Valid values: B1, S1, Y1"
  default     = "Y1"
}

variable "environment_type" {
  type = string
  description = "The type of the environment. e.g. dev, prod, test"
  default     = "dev"
}

variable "environment_name" {
  type = string
  description = "The name of the environment. e.g. sklearnmodel"
  default     = "sklearnmodel"
}

locals {
  environment_id = lower("${var.environment_name}-${var.environment_type}")
}