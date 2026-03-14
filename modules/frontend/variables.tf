/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "project_id" {
  description = "The project to deploy load balancer frontend resources.."
  type        = string
}

variable "region" {
  description = "The region where the load balancer will be created"
  type        = string
}

variable "name" {
  description = "Name for the forwarding rule and prefix for supporting resources"
  type        = string
}

variable "network" {
  description = "VPC network for the forwarding rule. It should not be default. The VPC network should have only one REGIONAL_MANAGED_PROXY subnetwork in the same region as of this regional load balancer. Please go to the subnets tab of your VPC network and check if a REGIONAL_MANAGED_PROXY subnet exists under `Reserved proxy-only subnets for load balancing` section. If the REGIONAL_MANAGED_PROXY doesn't exists, set create_proxy_only_subnet parameter to provision it as part of this component deployment."
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork that the load balanced IP should belong to, used in internal load balancing"
  type        = string
  default     = null
}

variable "create_proxy_only_subnet" {
  description = "Create a REGIONAL_MANAGED_PROXY subnetwork in the provided VPC network."
  type        = bool
  default     = false
}

variable "proxy_only_subnet_ip" {
  description = "ip_cidr_range for creating REGIONAL_MANAGED_PROXY subnetwork in the provided VPC network."
  type        = string
  default     = "10.129.0.0/23"
}

variable "load_balancing_scheme" {
  description = "Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL_MANAGED for Envoy-based load balancer, and INTERNAL_MANAGED for internal load balancer)"
  type        = string
  default     = "EXTERNAL_MANAGED"
}

variable "create_url_map" {
  description = "Set to `false` if url_map_resource_uri variable is provided."
  type        = bool
  default     = true
}

variable "url_map_input" {
  description = "List of host, path and backend service for creating url_map when create_url_map is set to true."
  type = list(object({
    host            = string
    path            = string
    backend_service = string
  }))
  default = []
}

variable "url_map_resource_uri" {
  description = "The url_map resource to use. This is the resource uri of the url map created out of band."
  type        = string
  default     = null
}

variable "create_address" {
  type        = bool
  description = "Create a new global IPv4 address"
  default     = true
}

variable "address" {
  type        = string
  description = "Existing IPv4 address to use (the actual IP address value)"
  default     = null
}

variable "enable_ipv6" {
  type        = bool
  description = "Enable IPv6 address on the CDN load-balancer"
  default     = false
}

variable "create_ipv6_address" {
  type        = bool
  description = "Allocate a new IPv6 address. Conflicts with \"ipv6_address\" - if both specified, \"create_ipv6_address\" takes precedence."
  default     = false
}

variable "ipv6_address" {
  type        = string
  description = "An existing IPv6 address to use (the actual IP address value)"
  default     = null
}

variable "labels" {
  description = "The labels to attach to resources created by this module"
  type        = map(string)
  default     = {}
}

variable "ssl" {
  description = "Set to `true` to enable SSL support. If `true` then at least one of these are required: 1) `ssl_certificates` OR 2) `create_ssl_certificate` set to `true` and `private_key/certificate` OR  3) `managed_ssl_certificate_domains`, OR 4) `certificate_map`"
  type        = bool
  default     = false
}

variable "create_ssl_certificate" {
  description = "If `true`, Create certificate using `private_key/certificate`"
  type        = bool
  default     = false
}

variable "private_key" {
  description = "Content of the private SSL key. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true`"
  type        = string
  default     = null
}

variable "certificate" {
  description = "Content of the SSL certificate. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true`"
  type        = string
  default     = null
}

variable "ssl_certificates" {
  description = "SSL cert self_link list. Requires `ssl` to be set to `true`"
  type        = list(string)
  default     = []
}

variable "managed_ssl_certificate_domains" {
  description = "Create Google-managed SSL certificates for specified domains. Requires `ssl` to be set to `true`"
  type        = list(string)
  default     = []
}

variable "random_certificate_suffix" {
  description = "Bool to enable/disable random certificate name generation. Set and keep this to true if you need to change the SSL cert."
  type        = bool
  default     = false
}

variable "certificate_manager_certificates" {
  description = "Certificate Manager cert self_link list. Requires `ssl` to be set to `true`"
  type        = list(string)
  default     = null
}

variable "http_port" {
  description = "The port for the HTTP load balancer"
  type        = number
  default     = 80
  validation {
    condition     = var.http_port >= 1 && var.http_port <= 65535
    error_message = "You must specify exactly one port between 1 and 65535"
  }
}

variable "https_port" {
  description = "The port for the HTTPS load balancer"
  type        = number
  default     = 443
  validation {
    condition     = var.https_port >= 1 && var.https_port <= 65535
    error_message = "You must specify exactly one port between 1 and 65535"
  }
}

variable "https_redirect" {
  description = "Set to `true` to enable https redirect on the lb."
  type        = bool
  default     = false
}

variable "http_forward" {
  description = "Set to `false` to disable HTTP port 80 forward"
  type        = bool
  default     = true
}

variable "ssl_policy" {
  type        = string
  description = "Selfink to SSL Policy"
  default     = null
}

variable "server_tls_policy" {
  description = "The resource URL for the server TLS policy to associate with the https proxy service"
  type        = string
  default     = null
}

variable "http_keep_alive_timeout_sec" {
  description = "Specifies how long to keep a connection open, after completing a response, while there is no matching traffic (in seconds)."
  type        = number
  default     = null
}
