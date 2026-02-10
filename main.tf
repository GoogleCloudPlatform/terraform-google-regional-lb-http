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

locals {
  address = var.create_address ? join("", google_compute_global_address.default[*].address) : var.address

  url_map             = var.create_url_map ? join("", google_compute_region_url_map.default[*].self_link) : var.url_map_resource_uri
  create_http_forward = var.http_forward || var.https_redirect

  is_internal = var.load_balancing_scheme == "INTERNAL_SELF_MANAGED"

  # Create a map with hosts as keys and empty lists as initial values
  hosts = toset([for service in var.url_map_input : service.host])
  backend_services_by_host = {
    for host in local.hosts :
    host => {
      for s in var.url_map_input :
      s.path => s.backend_service if s.host == host
    }
  }

  # Find a backend service to be used for url_map in absence of host "*" and path "/*"
  first_host            = keys(local.backend_services_by_host)[0]
  first_path            = keys(local.backend_services_by_host[local.first_host])[0]
  first_backend_service = local.backend_services_by_host[local.first_host][local.first_path]

  ssl_certificates = compact(concat(var.ssl_certificates, google_compute_ssl_certificate.default[*].self_link, google_compute_managed_ssl_certificate.default[*].self_link, ), )
}

resource "google_compute_region_backend_service" "default" {
  provider = google-beta

  project = var.project_id
  region  = var.region
  name    = "${var.name}-backend-service"

  load_balancing_scheme = var.load_balancing_scheme

  port_name = var.port_name
  protocol  = var.protocol

  description                     = var.description
  connection_draining_timeout_sec = var.connection_draining_timeout_sec
  enable_cdn                      = var.enable_cdn
  session_affinity                = var.session_affinity
  affinity_cookie_ttl_sec         = var.affinity_cookie_ttl_sec
  locality_lb_policy              = var.locality_lb_policy
  security_policy                 = var.security_policy
  timeout_sec                     = var.timeout_sec

  health_checks = var.health_check != null ? google_compute_region_health_check.default[*].self_link : null

  dynamic "backend" {
    for_each = toset(var.groups)
    content {
      description = lookup(backend.value, "description", null)
      group       = backend.value["group"]

      balancing_mode               = backend.value["balancing_mode"]
      capacity_scaler              = backend.value["capacity_scaler"]
      max_connections              = backend.value["max_connections"]
      max_connections_per_instance = backend.value["max_connections_per_instance"]
      max_connections_per_endpoint = backend.value["max_connections_per_endpoint"]
      max_rate                     = backend.value["max_rate"]
      max_rate_per_instance        = backend.value["max_rate_per_instance"]
      max_rate_per_endpoint        = backend.value["max_rate_per_endpoint"]
      max_utilization              = backend.value["max_utilization"]
    }
  }

  dynamic "backend" {
    for_each = toset(var.serverless_neg_backends)
    content {
      group           = google_compute_region_network_endpoint_group.serverless_negs["neg-${var.name}-${backend.value.region}"].id
      capacity_scaler = backend.value.capacity_scaler
    }
  }
}

resource "google_compute_region_health_check" "default" {
  provider = google-beta
  count    = var.health_check != null ? 1 : 0
  project  = var.project_id
  name     = "${var.name}-region-hc"
  region   = var.region

  check_interval_sec  = var.health_check.check_interval_sec
  timeout_sec         = var.health_check.timeout_sec
  healthy_threshold   = var.health_check.healthy_threshold
  unhealthy_threshold = var.health_check.unhealthy_threshold

  dynamic "http_health_check" {
    for_each = coalesce(var.health_check.protocol, var.protocol) == "HTTP" ? [
      1
    ] : []

    content {
      host               = var.health_check.host
      request_path       = var.health_check.request_path
      response           = var.health_check.response
      port               = var.health_check.port
      port_name          = var.health_check.port_name
      proxy_header       = var.health_check.proxy_header
      port_specification = var.health_check.port_specification
    }
  }

  dynamic "https_health_check" {
    for_each = coalesce(var.health_check.protocol, var.protocol) == "HTTPS" ? [
      1
    ] : []

    content {
      host               = var.health_check.host
      request_path       = var.health_check.request_path
      response           = var.health_check.response
      port               = var.health_check.port
      port_name          = var.health_check.port_name
      proxy_header       = var.health_check.proxy_header
      port_specification = var.health_check.port_specification
    }
  }

  dynamic "http2_health_check" {
    for_each = coalesce(var.health_check.protocol, var.protocol) == "HTTP2" ? [
      1
    ] : []

    content {
      host               = var.health_check.host
      request_path       = var.health_check.request_path
      response           = var.health_check.response
      port               = var.health_check.port
      port_name          = var.health_check.port_name
      proxy_header       = var.health_check.proxy_header
      port_specification = var.health_check.port_specification
    }
  }

  dynamic "tcp_health_check" {
    for_each = coalesce(var.health_check.protocol, var.protocol) == "TCP" ? [
      1
    ] : []

    content {
      request            = var.health_check.request
      response           = var.health_check.response
      port               = var.health_check.port
      port_name          = var.health_check.port_name
      proxy_header       = var.health_check.proxy_header
      port_specification = var.health_check.port_specification
    }
  }
}

resource "google_compute_firewall" "default_hc" {
  count   = var.health_check != null ? length(var.firewall_networks) : 0
  project = length(var.firewall_networks) == 1 && var.firewall_projects[0] == "default" ? var.project_id : var.firewall_projects[count.index]
  name    = "${var.name}-hc-${count.index}"
  network = var.firewall_networks[count.index]
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  target_tags             = length(var.target_tags) > 0 ? var.target_tags : null
  target_service_accounts = length(var.target_service_accounts) > 0 ? var.target_service_accounts : null

  allow {
    protocol = "tcp"
    ports    = [var.health_check.port]
  }

}

resource "google_compute_region_network_endpoint_group" "serverless_negs" {
  for_each = { for serverless_neg_backend in var.serverless_neg_backends :
  "neg-${var.name}-${serverless_neg_backend.region}" => serverless_neg_backend }


  provider              = google-beta
  project               = var.project_id
  name                  = each.key
  network_endpoint_type = "SERVERLESS"
  region                = each.value.region

  dynamic "cloud_run" {
    for_each = each.value.type == "cloud-run" ? [1] : []
    content {
      service = each.value.service_name
    }
  }

  dynamic "cloud_function" {
    for_each = each.value.type == "cloud-function" ? [1] : []
    content {
      function = each.value.service_name
    }
  }

  dynamic "app_engine" {
    for_each = each.value.type == "app-engine" ? [1] : []
    content {
      service = each.value.service_name
      version = each.value.service_version
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

### IPv4 ###
resource "google_compute_forwarding_rule" "default" {
  provider              = google-beta
  project               = var.project_id
  region                = var.region
  name                  = "${var.name}-forwarding-rule-http"
  target                = google_compute_region_target_http_proxy.default[0].self_link
  port_range            = var.http_port
  ip_address            = local.address
  load_balancing_scheme = var.load_balancing_scheme
  labels                = var.labels
  network               = var.network
}

resource "google_compute_forwarding_rule" "https" {
  name                  = "${var.name}-forwarding-rule-https"
  project               = var.project_id
  count                 = var.ssl ? 1 : 0
  target                = google_compute_region_target_https_proxy.default[0].self_link
  port_range            = var.https_port
  load_balancing_scheme = var.load_balancing_scheme
  ip_address            = local.address
  labels                = var.labels
  network               = var.network
}

resource "google_compute_global_address" "default" {
  provider   = google-beta
  count      = local.is_internal ? 0 : var.create_address ? 1 : 0
  project    = var.project_id
  name       = "${var.name}-address"
  ip_version = "IPV4"
  labels     = var.labels
}

resource "google_compute_address" "default" {
  provider   = google-beta
  count      = local.is_internal ? 0 : var.create_address ? 1 : 0
  project    = var.project_id
  region     = var.region
  name       = "${var.name}-address"
  ip_version = "IPV4"
  labels     = var.labels
}

### IPv4 ###

resource "google_compute_region_url_map" "default" {
  count           = var.create_url_map && length(local.backend_services_by_host) > 0 ? 1 : 0
  provider        = google-beta
  project         = var.project_id
  region          = var.region
  name            = "${var.name}-url-map"
  default_service = lookup(lookup(local.backend_services_by_host, "*", {}), "/*", local.first_backend_service)

  dynamic "host_rule" {
    for_each = local.backend_services_by_host
    content {
      hosts        = [host_rule.key]
      path_matcher = host_rule.key == "*" ? "default" : replace(host_rule.key, ".", "")
    }
  }

  dynamic "path_matcher" {
    for_each = local.backend_services_by_host
    content {
      name            = path_matcher.key == "*" ? "default" : replace(path_matcher.key, ".", "")
      default_service = path_matcher.value[contains(keys(path_matcher.value), "/*") ? "/*" : keys(path_matcher.value)[0]]

      dynamic "path_rule" {
        for_each = { for k, v in path_matcher.value : k => v if k != "/*" }
        content {
          paths   = [path_rule.key]
          service = path_rule.value
        }
      }
    }
  }
}

resource "google_compute_region_target_http_proxy" "default" {
  count   = local.create_http_forward ? 1 : 0
  name    = "${var.name}-regional-http-proxy"
  project = var.project_id
  region  = var.region
  url_map = var.https_redirect == false ? local.url_map : join("", google_compute_url_map.https_redirect[*].self_link)
}

# HTTPS proxy when ssl is true
resource "google_compute_region_target_https_proxy" "default" {
  project                          = var.project_id
  count                            = var.ssl ? 1 : 0
  name                             = "${var.name}-regional-https-proxy"
  region                           = var.region
  url_map                          = local.url_map
  ssl_certificates                 = length(local.ssl_certificates) > 0 ? local.ssl_certificates : null
  certificate_manager_certificates = var.certificate_manager_certificates
  ssl_policy                       = var.ssl_policy
  server_tls_policy                = var.server_tls_policy
  http_keep_alive_timeout_sec      = var.http_keep_alive_timeout_sec
}

resource "google_compute_ssl_certificate" "default" {
  project     = var.project_id
  count       = var.ssl && var.create_ssl_certificate ? 1 : 0
  name_prefix = "${var.name}-certificate-"
  private_key = var.private_key
  certificate = var.certificate

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_id" "certificate" {
  count       = var.random_certificate_suffix == true ? 1 : 0
  byte_length = 4
  prefix      = "${var.name}-cert-"

  keepers = {
    domains = join(",", var.managed_ssl_certificate_domains)
  }
}

resource "google_compute_managed_ssl_certificate" "default" {
  provider = google-beta
  project  = var.project_id
  count    = var.ssl && length(var.managed_ssl_certificate_domains) > 0 ? 1 : 0
  name     = var.random_certificate_suffix == true ? random_id.certificate[0].hex : "${var.name}-cert"

  lifecycle {
    create_before_destroy = true
  }

  managed {
    domains = var.managed_ssl_certificate_domains
  }
}

resource "google_compute_url_map" "https_redirect" {
  project = var.project_id
  count   = var.https_redirect ? 1 : 0
  name    = "${var.name}-https-redirect"
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}



