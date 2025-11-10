variable "project" {
  description = "GCP project ID (alias used in some places)"
  type        = string
}

variable "regions" {
  description = "Regions where to create regional ALBs"
  type        = map(string)
  default     = {
    "us-central1" = "us-central1"
    "us-east1"    = "us-east1"
  }
}

variable "vm_subnet_cidrs" {
  description = "VM subnet CIDRs per region"
  type        = map(string)
  default     = {
    "us-central1" = "10.10.0.0/24"
    "us-east1"    = "10.20.0.0/24"
  }
}

variable "proxy_subnet_cidrs" {
  description = "Proxy-only subnet CIDRs per region"
  type        = map(string)
  default     = {
    "us-central1" = "10.30.0.0/24"
    "us-east1"    = "10.40.0.0/24"
  }
}

variable "default_region" {
  description = "Default region used for the provider"
  type        = string
  default     = "us-central1"
}

variable "region_to_zone" {
  description = "Region -> zone mapping for MIGs"
  type        = map(string)
  default     = {
    "us-central1" = "us-central1-a"
    "us-east1"    = "us-east1-b"
  }
}

variable "instance_image" {
  description = "Image for test instances"
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-11"
}

variable "instance_machine_type" {
  description = "Machine type"
  type        = string
  default     = "e2-medium"
}

variable "target_size" {
  description = "Number of VMs per MIG"
  type        = number
  default     = 2
}

variable "regional_hostname" {
  description = "DNS hostname used for certificates and DNS records"
  type        = string
  default     = "regional.example.com"
}

variable "enable_dns_records" {
  description = "Whether to create DNS records"
  type        = bool
  default     = true
}

variable "create_public_zone" {
  description = "Whether to create a new public managed zone"
  type        = bool
  default     = true
}

variable "public_zone_name" {
  description = "Name of an existing public managed zone (used if create_public_zone=false)"
  type        = string
  default     = "public-example-zone"
}
