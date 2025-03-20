/**
 * Copyright 2025 Google LLC
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

resource "google_compute_network" "default" {
  name                    = "lb-internal-cloud-run"
  auto_create_subnetworks = "false"
  project                 = var.project_id
}

resource "google_compute_subnetwork" "default" {
  name          = "lb-internal-subnet-cloud-run"
  ip_cidr_range = "10.1.2.0/24"
  network       = google_compute_network.default.id
  region        = var.region
  project       = var.project_id
}

resource "google_compute_subnetwork" "proxy_only" {
  name          = "proxy-only-subnet-int"
  ip_cidr_range = "10.129.0.0/23"
  network       = google_compute_network.default.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  region        = var.region
  project       = var.project_id
  role          = "ACTIVE"
}

module "backend-service" {
  source                        = "GoogleCloudPlatform/cloud-run/google//modules/v2"
  version                       = "~> 0.17.0"
  project_id                    = var.project_id
  location                      = var.region
  service_name                  = "bs-2002"
  containers                    = [{ "container_name" = "", "container_image" = "gcr.io/cloudrun/hello" }]
  members                       = ["allUsers"]
  ingress                       = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  cloud_run_deletion_protection = false
  enable_prometheus_sidecar     = false
}

module "lb-http-backend" {
  source  = "GoogleCloudPlatform/regional-lb-http/google//modules/backend"
  version = "~> 0.4.0"

  project_id            = var.project_id
  region                = var.region
  name                  = "backend-lb-int"
  enable_cdn            = false
  load_balancing_scheme = "INTERNAL_MANAGED"

  serverless_neg_backends = [{ region : "us-central1", type : "cloud-run", service_name : module.backend-service.service_name }]
}

module "lb-http-frontend" {
  source  = "GoogleCloudPlatform/regional-lb-http/google//modules/frontend"
  version = "~> 0.4.0"

  project_id            = var.project_id
  region                = var.region
  name                  = "frontend-lb-int"
  url_map_input         = module.lb-http-backend.backend_service_info
  network               = google_compute_network.default.name
  subnetwork            = google_compute_subnetwork.default.name
  load_balancing_scheme = "INTERNAL_MANAGED"

  depends_on = [google_compute_subnetwork.proxy_only]
}

resource "google_vpc_access_connector" "default" {
  provider       = google-beta
  project        = var.project_id
  name           = "fe-vpc-cx"
  ip_cidr_range  = "10.8.0.0/28"
  network        = google_compute_network.default.name
  region         = var.region
  max_throughput = 500
  min_throughput = 300
}

module "frontend-service" {
  source       = "GoogleCloudPlatform/cloud-run/google//modules/v2"
  version      = "~> 0.17.0"
  project_id   = var.project_id
  location     = var.region
  service_name = "fs-2002"
  containers   = [{ "env_vars" : { "TARGET_IP" : module.lb-http-frontend.ip_address_http }, "ports" = { "container_port" = 80, "name" = "http1" }, "container_name" = "", "container_image" = "gcr.io/design-center-container-repo/redirect-traffic:latest-2002" }]
  members      = ["allUsers"]
  vpc_access = {
    connector = google_vpc_access_connector.default.id
    egress    = "ALL_TRAFFIC"
  }
  ingress                       = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  cloud_run_deletion_protection = false
  enable_prometheus_sidecar     = false
}

module "lb-http-backend-ext" {
  source  = "GoogleCloudPlatform/regional-lb-http/google//modules/backend"
  version = "~> 0.4.0"

  project_id = var.project_id
  region     = var.region
  name       = "backend-lb-ext"
  enable_cdn = false

  serverless_neg_backends = [{ region : "us-central1", type : "cloud-run", service_name : module.frontend-service.service_name }]
}

module "lb-http-frontend-ext" {
  source  = "GoogleCloudPlatform/regional-lb-http/google//modules/frontend"
  version = "~> 0.4.0"

  project_id    = var.project_id
  region        = var.region
  name          = "frontend-lb-ext"
  url_map_input = module.lb-http-backend-ext.backend_service_info
  network       = google_compute_network.default.name

  depends_on = [google_compute_subnetwork.proxy_only]
}
