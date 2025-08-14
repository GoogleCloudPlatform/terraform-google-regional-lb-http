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


output "external_ip" {
  description = "The external IPv4 assigned to the fowarding rule."
  value       = local.address
}

output "ip_address_http" {
  description = "The internal/external IP address assigned to the HTTP forwarding rule."
  value       = try(google_compute_forwarding_rule.default[0].ip_address, "")
}

output "ip_address_https" {
  description = "The internal/external IP address assigned to the HTTPS forwarding rule."
  value       = try(google_compute_forwarding_rule.https[0].ip_address, "")
}

output "http_proxy" {
  description = "The HTTP proxy used by this module."
  value       = google_compute_region_target_http_proxy.default[*].self_link
}

output "https_proxy" {
  description = "The HTTPS proxy used by this module."
  value       = google_compute_region_target_https_proxy.default[*].self_link
}

output "url_map" {
  description = "The URL map used by this load balancer frontend."
  value       = local.url_map
}

output "ssl_certificate_created" {
  description = "The SSL certificate create from key/pem"
  value       = google_compute_ssl_certificate.default[*].self_link
}

output "apphub_service_uri" {
  value = concat(
    local.create_http_forward ? [
      {
        service_uri = "//compute.googleapis.com/${google_compute_forwarding_rule.default[0].id}"
        service_id  = substr("${google_compute_forwarding_rule.default[0].name}-${md5("google-regional-lb-http-${var.region}-${var.project_id}")}", 0, 63)
        location    = var.region
      }
    ] : [],
    var.ssl ? [
      {
        service_uri = "//compute.googleapis.com/${google_compute_forwarding_rule.https[0].id}"
        service_id  = substr("${google_compute_forwarding_rule.https[0].name}-${md5("google-regional-lb-http-${var.region}-${var.project_id}")}", 0, 63)
        location    = var.region
      }
    ] : [],
    (var.enable_ipv6 && local.create_http_forward) ? [
      {
        service_uri = "//compute.googleapis.com/${google_compute_forwarding_rule.http_ipv6[0].id}"
        service_id  = substr("${google_compute_forwarding_rule.http_ipv6[0].name}-${md5("google-regional-lb-http-${var.region}-${var.project_id}")}", 0, 63)
        location    = var.region
      }
    ] : [],
    var.enable_ipv6 && var.ssl ? [
      {
        service_uri = "//compute.googleapis.com/${google_compute_forwarding_rule.https_ipv6[0].id}"
        service_id  = substr("${google_compute_forwarding_rule.https_ipv6[0].name}-${md5("google-regional-lb-http-${var.region}-${var.project_id}")}", 0, 63)
        location    = var.region
      }
    ] : []
  )
  description = "A list of all App Hub service URIs, including HTTP, HTTPS, and IPv6 versions."
}
