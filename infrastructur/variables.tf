variable "location" {
  type        = string
  description = "Azure region"
  default     = "norwayeast"
}

variable "resource_group_name" {
  type    = string
  default = "clco-demo-rg"
}

variable "app_service_plan_name" {
  type    = string
  default = "clco-demo-plan"
}

variable "webapp_name" {
  type    = string
  default = "clco-demo-webapp"
}

variable "vnet_name" {
  type    = string
  default = "clco-demo-vnet"
}

variable "webapp_subnet_name" {
  type    = string
  default = "webapp-subnet"
}

variable "ai_subnet_name" {
  type    = string
  default = "ai-subnet"
}

variable "subscription_id" {
  type        = string
  description = "Your Azure Subscription ID"
}

variable "cognitive_account_name" {
  type    = string
  default = "clco-langservice"
}

variable "cognitive_sku" {
  type    = string
  default = "S"
}
