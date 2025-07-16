variable "subscription_id" {
  description = "The subscription ID to use for the Azure provider"
  type        = string
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to use for the AKS clusters"
  type        = string
  default     = "1.33.1"
}

variable "clusters" {
  description = "A list of AKS clusters to create, each with a name and location"
  type = list(object({
    name     = string
    location = string
  }))
  default = [
    {
      name     = "aks-gwc"
      location = "germanywestcentral"
    },
    {
      name     = "aks-sdc"
      location = "swedencentral"
    }
  ]
}

variable "fleetmanager_enabled" {
  description = "Whether to create the AKS fleet manager"
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "The name of the DNS zone to create for the AKS clusters"
  type        = string
}

variable "loadbalanced_dns_zone_name" {
  description = "The name of the DNS zone for load balancing"
  type        = string
}