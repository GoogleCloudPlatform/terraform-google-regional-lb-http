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

resource "google_compute_network" "default" {
  name                    = "lb-network-cloud-run"
  auto_create_subnetworks = "false"
  project                 = var.project_id
}

resource "google_compute_subnetwork" "default" {
  name          = "test-regional-lb-subnetwork-cloud-run"
  ip_cidr_range = "10.1.2.0/24"
  network       = google_compute_network.default.id
  region        = var.region
  project       = var.project_id
}

resource "google_compute_subnetwork" "proxy_only" {
  name          = "proxy-only-subnetwork"
  ip_cidr_range = "10.129.0.0/23"
  network       = google_compute_network.default.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  region        = var.region
  project       = var.project_id
  role          = "ACTIVE"
}

module "lb-http-backend" {
  source     = "GoogleCloudPlatform/regional-lb-http/google//modules/backend"
  version    = "~> 0.4.0"
  project_id = var.project_id
  region     = var.region
  name       = "backend-lb"
  enable_cdn = false

  serverless_neg_backends = [{ region : "us-central1", type : "cloud-run", service_name : google_cloud_run_service.default.name }]

}

module "lb-http-frontend" {
  source        = "GoogleCloudPlatform/regional-lb-http/google//modules/frontend"
  version       = "~> 0.4.0"
  project_id    = var.project_id
  region        = var.region
  name          = "frontend-lb"
  url_map_input = module.lb-http-backend.backend_service_info
  network       = google_compute_network.default.name
  depends_on    = [google_compute_subnetwork.proxy_only]
}

resource "google_cloud_run_service" "default" {
  name     = "example-1"
  location = var.region
  project  = var.project_id

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }
  metadata {
    annotations = {
      # For valid annotation values and descriptions, see
      # https://cloud.google.com/sdk/gcloud/reference/run/deploy#--ingress
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }
}

resource "google_cloud_run_service_iam_member" "public-access" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
