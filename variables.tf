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

variable "name" {
  description = "Name for the backend service."
  type        = string
}

variable "project_id" {
  description = "The project to deploy to, if not set the default provider project is used."
  type        = string
}

variable "region" {
  description = "The region where the load balancer backend service will be created"
  type        = string
}

variable "load_balancing_scheme" {
  description = "Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL_MANAGED for Envoy-based load balancer, and INTERNAL_SELF_MANAGED for traffic director)"
  type        = string
  default     = "EXTERNAL_MANAGED"
}

variable "protocol" {
  description = "The protocol this BackendService uses to communicate with backends."
  type        = string
  default     = "HTTP"
}

variable "port_name" {
  description = "Name of backend port. The same name should appear in the instance groups referenced by this service. Required when the load balancing scheme is EXTERNAL."
  type        = string
  default     = "http"
}

variable "description" {
  description = "Description of the backend service."
  type        = string
  default     = null
}

variable "connection_draining_timeout_sec" {
  description = "Time for which instance will be drained (not accept new connections, but still work to finish started)."
  type        = number
  default     = null
}

variable "enable_cdn" {
  description = "Enable Cloud CDN for this BackendService."
  type        = bool
  default     = false
}

variable "session_affinity" {
  description = "Type of session affinity to use. Possible values are: NONE, CLIENT_IP, CLIENT_IP_PORT_PROTO, CLIENT_IP_PROTO, GENERATED_COOKIE, HEADER_FIELD, HTTP_COOKIE, STRONG_COOKIE_AFFINITY."
  type        = string
  default     = null
}

variable "affinity_cookie_ttl_sec" {
  description = "Lifetime of cookies in seconds if session_affinity is GENERATED_COOKIE."
  type        = number
  default     = null
}

variable "locality_lb_policy" {
  description = "The load balancing algorithm used within the scope of the locality."
  type        = string
  default     = null
}

variable "security_policy" {
  description = "Security policy in string."
  type        = string
  default     = null
}

variable "timeout_sec" {
  description = "This has different meaning for different type of load balancing. Please refer https://cloud.google.com/load-balancing/docs/backend-service#timeout-setting"
  type        = number
  default     = null
}

variable "health_check" {
  description = "Input for creating HttpHealthCheck or HttpsHealthCheck resource for health checking this BackendService. A health check must be specified unless the backend service uses an internet or serverless NEG as a backend."
  type = object({
    host                = optional(string, null)
    request_path        = optional(string, null)
    request             = optional(string, null)
    response            = optional(string, null)
    port                = optional(number, null)
    port_name           = optional(string, null)
    proxy_header        = optional(string, null)
    port_specification  = optional(string, null)
    protocol            = optional(string, null)
    check_interval_sec  = optional(number, 10)
    timeout_sec         = optional(number, 10)
    healthy_threshold   = optional(number, 2)
    unhealthy_threshold = optional(number, 2)
    logging             = optional(bool, true)
  })
  default = null
}

variable "firewall_networks" {
  description = "Names of the networks to create firewall rules in"
  type        = list(string)
  default     = ["default"]
}

variable "firewall_projects" {
  description = "Names of the projects to create firewall rules in"
  type        = list(string)
  default     = ["default"]
}

variable "target_tags" {
  description = "List of target tags for health check firewall rule. Exactly one of target_tags or target_service_accounts should be specified."
  type        = list(string)
  default     = []
}

variable "target_service_accounts" {
  description = "List of target service accounts for health check firewall rule. Exactly one of target_tags or target_service_accounts should be specified."
  type        = list(string)
  default     = []
}

variable "serverless_neg_backends" {
  description = "The list of serverless backend which serves the traffic."
  type = list(object({
    region          = string
    type            = string // cloud-run, cloud-function, and app-engine
    service_name    = string
    service_version = optional(string)
    capacity_scaler = optional(number, 1.0)
  }))
  default = []
}

variable "groups" {
  description = "The list of backend instance group which serves the traffic."
  type = list(object({
    group       = string
    description = optional(string)

    balancing_mode               = optional(string)
    capacity_scaler              = optional(number)
    max_connections              = optional(number)
    max_connections_per_instance = optional(number)
    max_connections_per_endpoint = optional(number)
    max_rate                     = optional(number)
    max_rate_per_instance        = optional(number)
    max_rate_per_endpoint        = optional(number)
    max_utilization              = optional(number)
  }))
  default = []
}

variable "create_address" {
  type        = bool
  description = "Create a new global IPv4 address"
  default     = true
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

variable "network" {
  description = "Network for INTERNAL_SELF_MANAGED load balancing scheme"
  type        = string
  default     = "default"
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

variable "create_url_map" {
  description = "Set to `false` if url_map variable is provided."
  type        = bool
  default     = true
}

variable "https_redirect" {
  description = "Set to `true` to enable https redirect on the lb."
  type        = bool
  default     = false
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

variable "address" {
  type        = string
  description = "Existing IPv4 address to use (the actual IP address value)"
  default     = null
}

variable "http_forward" {
  description = "Set to `false` to disable HTTP port 80 forward"
  type        = bool
  default     = true
}

variable "url_map_input" {
  description = "List of host, path and backend service for creating url_map"
  type = list(object({
    host            = string
    path            = string
    backend_service = string
  }))
  default = []
}

variable "url_map_resource_uri" {
  description = "The url_map resource to use. Default is to send all traffic to first backend."
  type        = string
  default     = null
}

