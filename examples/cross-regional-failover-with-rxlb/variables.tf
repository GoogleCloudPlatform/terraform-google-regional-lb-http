variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "project" {
  description = "ID do projeto GCP (alias usado em alguns lugares)"
  type        = string
}

variable "regions" {
  description = "Regiões onde criar os ALBs regionais"
  type        = map(string)
  default     = {
    "us-central1" = "us-central1"
    "us-east1"    = "us-east1"
  }
}

variable "vm_subnet_cidrs" {
  description = "CIDRs das subnets de VM por região"
  type        = map(string)
  default     = {
    "us-central1" = "10.10.0.0/24"
    "us-east1"    = "10.20.0.0/24"
  }
}

variable "proxy_subnet_cidrs" {
  description = "CIDRs das proxy-only subnets por região"
  type        = map(string)
  default     = {
    "us-central1" = "10.30.0.0/24"
    "us-east1"    = "10.40.0.0/24"
  }
}


variable "default_region" {
  description = "Região padrão usada para provider"
  type        = string
  default     = "us-central1"
}

variable "region_to_zone" {
  description = "Mapeamento região -> zona para os MIGs"
  type        = map(string)
  default     = {
    "us-central1" = "us-central1-a"
    "us-east1"    = "us-east1-b"
  }
}

variable "instance_image" {
  description = "Imagem para instâncias de teste"
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-11"
}

variable "instance_machine_type" {
  description = "Tipo de máquina"
  type        = string
  default     = "e2-medium"
}

variable "target_size" {
  description = "Número de VMs por MIG"
  type        = number
  default     = 2
}

variable "regional_hostname" {
  description = "Hostname DNS usado para certificados e DNS records"
  type        = string
  default     = "regional.example.com"
}

variable "enable_dns_records" {
  description = "Se deve criar registros DNS"
  type        = bool
  default     = true
}

variable "create_public_zone" {
  description = "Se deve criar nova managed zone pública"
  type        = bool
  default     = true
}

variable "public_zone_name" {
  description = "Nome da managed zone pública existente (se create_public_zone=false)"
  type        = string
  default     = "public-example-zone"
}
