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
  is_internal = var.load_balancing_scheme == "INTERNAL_SELF_MANAGED" || var.load_balancing_scheme == "INTERNAL_MANAGED"
  address     = var.create_address ? join("", google_compute_address.default[*].address) : var.address

  url_map             = var.create_url_map ? join("", google_compute_region_url_map.default[*].self_link) : var.url_map_resource_uri
  create_http_forward = var.http_forward || var.https_redirect
  ipv6_address        = var.create_ipv6_address ? join("", google_compute_address.default_ipv6[*].address) : var.ipv6_address

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
  first_host            = try(keys(local.backend_services_by_host)[0], null)
  first_path            = try(keys(local.backend_services_by_host[local.first_host])[0], null)
  first_backend_service = try(local.backend_services_by_host[local.first_host][local.first_path], null)

  ssl_certificates = compact(concat(var.ssl_certificates, google_compute_ssl_certificate.default[*].self_link, google_compute_managed_ssl_certificate.default[*].self_link, ), )
}

### Proxy only subnetwork ###
resource "google_compute_subnetwork" "proxy_only" {
  count         = var.create_proxy_only_subnet ? 1 : 0
  name          = "${var.name}-proxy-only-subnetwork"
  ip_cidr_range = var.proxy_only_subnet_ip
  network       = var.network
  purpose       = "REGIONAL_MANAGED_PROXY"
  region        = var.region
  project       = var.project_id
  role          = "ACTIVE"
}

### IPv4 ###

resource "google_compute_forwarding_rule" "default" {
  provider              = google-beta
  count                 = local.create_http_forward ? 1 : 0
  project               = var.project_id
  region                = var.region
  name                  = "${var.name}-forwarding-rule-http"
  target                = google_compute_region_target_http_proxy.default[0].self_link
  port_range            = var.http_port
  ip_address            = local.address
  load_balancing_scheme = var.load_balancing_scheme
  labels                = var.labels
  network               = var.network
  subnetwork            = var.subnetwork
  depends_on            = [google_compute_subnetwork.proxy_only]
}

resource "google_compute_forwarding_rule" "https" {
  name                  = "${var.name}-forwarding-rule-https"
  project               = var.project_id
  region                = var.region
  count                 = var.ssl ? 1 : 0
  target                = google_compute_region_target_https_proxy.default[0].self_link
  port_range            = var.https_port
  load_balancing_scheme = var.load_balancing_scheme
  ip_address            = local.address
  labels                = var.labels
  network               = var.network
  subnetwork            = var.subnetwork
  depends_on            = [google_compute_subnetwork.proxy_only]
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

### IPv6 block ###
resource "google_compute_forwarding_rule" "http_ipv6" {
  provider = google-beta
  count    = (var.enable_ipv6 && local.create_http_forward) ? 1 : 0

  project               = var.project_id
  region                = var.region
  name                  = "${var.name}-forwarding-rule-ipv6-http"
  target                = google_compute_region_target_http_proxy.default[0].self_link
  ip_address            = local.ipv6_address
  port_range            = var.http_port
  labels                = var.labels
  load_balancing_scheme = var.load_balancing_scheme
  network               = var.network
  subnetwork            = var.subnetwork
  depends_on            = [google_compute_subnetwork.proxy_only]
}

resource "google_compute_forwarding_rule" "https_ipv6" {
  count = var.enable_ipv6 && var.ssl ? 1 : 0

  project               = var.project_id
  region                = var.region
  name                  = "${var.name}-forwarding-rule-ipv6-https"
  target                = google_compute_region_target_https_proxy.default[0].self_link
  ip_address            = local.ipv6_address
  port_range            = var.https_port
  labels                = var.labels
  load_balancing_scheme = var.load_balancing_scheme
  network               = var.network
  subnetwork            = var.subnetwork
  depends_on            = [google_compute_subnetwork.proxy_only]
}

resource "google_compute_address" "default_ipv6" {
  provider = google-beta
  count    = local.is_internal ? 0 : (var.enable_ipv6 && var.create_ipv6_address) ? 1 : 0

  project    = var.project_id
  region     = var.region
  name       = "${var.name}-ipv6-address"
  ip_version = "IPV6"
  labels     = var.labels
}

### IPv6 block ###

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
