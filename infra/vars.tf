variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default = {
    owner   = "nagato"
    project = "lazarus"
  }
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "ukwest"
}

variable "prefix" {
  description = "A prefix to use for naming resources."
  type        = string
  default     = "laz"
}

variable "sku_name" {
  description = "The SKU name for the App Service Plan."
  type        = string
  default     = "S1"
}

locals {
  web_app_log_categories = [
    "AppServiceHTTPLogs",
    "AppServiceConsoleLogs",
    "AppServiceAppLogs",
    "AppServicePlatformLogs",
  ]
}
