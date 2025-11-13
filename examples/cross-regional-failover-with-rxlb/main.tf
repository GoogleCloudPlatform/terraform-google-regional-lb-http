resource "google_compute_network" "auto" {
  name                    = "regional-lb-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vm" {
  for_each      = var.vm_subnet_cidrs
  name          = "regional-${each.key}-vm-subnet"
  region        = each.key
  network       = google_compute_network.auto.self_link
  ip_cidr_range = each.value
  stack_type    = "IPV4_ONLY"
}

resource "google_compute_subnetwork" "proxy_only" {
  for_each      = var.regions
  name          = "regional-${each.key}-proxy-subnet"
  region        = each.key
  network       = google_compute_network.auto.self_link
  ip_cidr_range = var.proxy_subnet_cidrs[each.key]
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  stack_type    = "IPV4_ONLY"
}

resource "google_compute_region_security_policy" "armor" {
  for_each = var.regions
  name     = "regional-${each.key}-armor"
  region   = each.key
  type     = "CLOUD_ARMOR"

  rules {
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["0.0.0.0/0"]
      }
    }
    action      = "allow"
    description = "Allow all traffic"
  }

  rules {
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    action      = "deny(403)"
    description = "Default rule to deny all other traffic"
  }
}

resource "google_compute_instance_template" "tmpl" {
  for_each     = var.regions
  name_prefix  = "regional-${each.key}-tmpl"
  machine_type = var.instance_machine_type

  lifecycle {
    create_before_destroy = true
  }

  disk {
    source_image = var.instance_image
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vm[each.key].self_link
    access_config {}
  }
  
  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo "hello from ${each.key} $(hostname)" > /var/www/html/index.html
    systemctl enable nginx
    systemctl restart nginx
  EOT

  tags = ["allow-hc", "allow-proxy"]
}

resource "google_compute_instance_group_manager" "mig" {
  for_each           = var.regions
  name               = "regional-${each.key}-mig"
  base_instance_name = "regional-${each.key}-vm"
  zone               = var.region_to_zone[each.key]
  target_size        = var.target_size

  version {
    instance_template = google_compute_instance_template.tmpl[each.key].self_link
  }

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_region_health_check" "hc" {
  for_each = var.regions
  name     = "regional-${each.key}-hc"
  region   = each.key

  http_health_check {
    port         = 80
    request_path = "/"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

resource "google_compute_region_backend_service" "bs" {
  provider              = google-beta
  for_each              = var.regions
  name                  = "regional-${each.key}-bs"
  region                = each.key
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  timeout_sec           = 30
  health_checks         = [google_compute_region_health_check.hc[each.key].self_link]

  security_policy       = google_compute_region_security_policy.armor[each.key].self_link

  backend {
    group           = google_compute_instance_group_manager.mig[each.key].instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_region_url_map" "um" {
  for_each        = var.regions
  name            = "regional-${each.key}-url-map"
  region          = each.key
  default_service = google_compute_region_backend_service.bs[each.key].self_link
}

resource "google_compute_region_target_http_proxy" "http" {
  for_each = var.regions
  name     = "regional-${each.key}-http-proxy"
  region   = each.key
  url_map  = google_compute_region_url_map.um[each.key].self_link
}

resource "google_compute_region_target_https_proxy" "https" {
  provider = "google-beta"
  for_each = var.regions
  name     = "regional-${each.key}-https-proxy"
  region   = each.key
  url_map  = google_compute_region_url_map.um[each.key].self_link

  certificate_manager_certificates = [
     google_certificate_manager_certificate.cert[each.key].id
  ]

  depends_on = [
    google_certificate_manager_certificate.cert
  ]
  
}

resource "google_compute_address" "addr" {
  for_each = var.regions
  name     = "regional-${each.key}-ip"
  region   = each.key
}

resource "google_compute_forwarding_rule" "http" {
  for_each              = var.regions
  name                  = "regional-${each.key}-fr-http"
  region                = each.key
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  ip_address            = google_compute_address.addr[each.key].address
  target                = google_compute_region_target_http_proxy.http[each.key].self_link
  network_tier          = "PREMIUM"
  network               = google_compute_network.auto.self_link
  depends_on            = [google_compute_subnetwork.proxy_only]
}

resource "google_compute_forwarding_rule" "https" {
  for_each              = var.regions
  name                  = "regional-${each.key}-fr-https"
  region                = each.key
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  ip_address            = google_compute_address.addr[each.key].address
  target                = google_compute_region_target_https_proxy.https[each.key].self_link
  network_tier          = "PREMIUM"
  network               = google_compute_network.auto.self_link
  depends_on            = [google_compute_subnetwork.proxy_only]
}

resource "google_dns_record_set" "regional_geo_a" {
  count = var.enable_dns_records && length(local.ordered_regions) > 0 ? 1 : 0

  lifecycle {
    replace_triggered_by  = [google_compute_address.addr]
    ignore_changes        = [rrdatas]
  }

  managed_zone = local.dns_managed_zone_name
  name         = "${var.regional_hostname}."
  type         = "A"
  ttl          = 60

  routing_policy {
    enable_geo_fencing = false
    dynamic "geo" {
      for_each = var.regions
      content {
        location = geo.key
        rrdatas  = [google_compute_address.addr[geo.key].address]
      }
    }
  }
}

resource "google_certificate_manager_dns_authorization" "auth" {
  for_each = var.regions
  provider = google-beta
  name     = "regional-${each.key}-dns-auth"
  location = each.key
  domain   = var.regional_hostname
}

locals {
  ordered_regions = sort(keys(var.regions))
  dns_managed_zone_name  = coalesce(
    try(google_dns_managed_zone.public_new[0].name, null),
    var.public_zone_name
  )
}

resource "google_dns_record_set" "acme_txt" {
  for_each     = (var.enable_dns_records && length(local.ordered_regions) > 0) ? google_certificate_manager_dns_authorization.auth : {}
  managed_zone = local.dns_managed_zone_name
  name         = each.value.dns_resource_record[0].name
  type         = "TXT"
  ttl          = 60
  rrdatas      = [each.value.dns_resource_record[0].data]
}


resource "google_certificate_manager_certificate" "cert" {
  for_each = var.regions
  provider = google-beta
  name     = "regional-${each.key}-cm-cert"
  location = each.key 

  managed {
    domains            = [var.regional_hostname]
    dns_authorizations = [google_certificate_manager_dns_authorization.auth[each.key].id]
  }
  depends_on = [
    google_dns_record_set.acme_txt
  ]
}

resource "google_dns_managed_zone" "public_new" {
  count       = var.create_public_zone && var.enable_dns_records ? 1 : 0
  name        = format("public-%s", replace(var.regional_hostname, ".", "-"))
  dns_name    = "${var.regional_hostname}."
  description = "Public zone for ${var.regional_hostname}"
}

resource "google_compute_firewall" "allow_hc" {
  name    = "allow-hc"
  network = google_compute_network.auto.name
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["allow-hc"]
}

resource "google_compute_firewall" "allow_proxy_to_backend" {
  name    = "allow-proxy-to-backend"
  network = google_compute_network.auto.name

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["allow-proxy"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}
