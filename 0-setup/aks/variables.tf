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