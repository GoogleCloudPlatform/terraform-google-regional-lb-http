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
  iap_access_members = var.iap_config.enable ? coalesce(var.iap_config.iap_members, []) : []
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
      capacity_scaler              = var.load_balancing_scheme != "INTERNAL" ? backend.value["capacity_scaler"] : null
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
      group           = google_compute_region_network_endpoint_group.serverless_negs["neg-${var.name}-${backend.value.region}-${substr(md5(backend.value.service_name), 0, 4)}"].id
      capacity_scaler = var.load_balancing_scheme != "INTERNAL" ? backend.value.capacity_scaler : null
    }
  }

  dynamic "iap" {
    for_each = var.iap_config.enable ? [1] : []
    content {
      oauth2_client_id     = lookup(var.iap_config, "oauth2_client_id", "")
      enabled              = var.iap_config.enable
      oauth2_client_secret = lookup(var.iap_config, "oauth2_client_secret", "")
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
    ports    = var.health_check.port != null ? [var.health_check.port] : null
  }
}

resource "google_compute_firewall" "allow_proxy" {
  count         = var.health_check != null ? length(var.firewall_networks) : 0
  project       = length(var.firewall_networks) == 1 && var.firewall_projects[0] == "default" ? var.project_id : var.firewall_projects[count.index]
  name          = "${var.name}-fw-allow-proxies-${count.index}"
  network       = var.firewall_networks[count.index]
  source_ranges = var.firewall_source_ranges
  target_tags   = length(var.target_tags) > 0 ? var.target_tags : null

  allow {
    ports    = ["443"]
    protocol = "tcp"
  }
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }
  allow {
    ports    = ["8080"]
    protocol = "tcp"
  }
}

resource "google_compute_region_network_endpoint_group" "serverless_negs" {
  for_each = { for serverless_neg_backend in var.serverless_neg_backends :
  "neg-${var.name}-${serverless_neg_backend.region}-${substr(md5(serverless_neg_backend.service_name), 0, 4)}" => serverless_neg_backend }


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

resource "google_iap_web_region_backend_service_iam_member" "member" {
  for_each                   = toset(local.iap_access_members)
  project                    = google_compute_region_backend_service.default.project
  region                     = google_compute_region_backend_service.default.region
  web_region_backend_service = google_compute_region_backend_service.default.name
  role                       = "roles/iap.httpsResourceAccessor"
  member                     = each.value
}
