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
  name                    = "lb-network-mig"
  auto_create_subnetworks = "false"
  project                 = var.project_id
}

resource "google_compute_subnetwork" "default" {
  name          = "test-regional-lb-subnetwork-mig"
  ip_cidr_range = "10.1.2.0/24"
  network       = google_compute_network.default.id
  region        = "us-central1"
  project       = var.project_id
}

module "lb-http-backend" {
  source  = "GoogleCloudPlatform/regional-lb-http/google//modules/backend"
  version = "~> 0.0.1"

  project_id = var.project_id
  region     = "us-central1"
  name       = "backend-lb-mig"
  enable_cdn = false

  groups = [{ group : module.mig.instance_group }]
  health_check = {
    protocol : "HTTP",
    port_specification = "USE_SERVING_PORT"
    proxy_header       = "NONE"
    request_path       = "/"
  }
  firewall_networks = [google_compute_network.default.name]
  target_tags = [
    "load-balanced-backend"
  ]
}

module "lb-http-frontend" {
  source        = "GoogleCloudPlatform/regional-lb-http/google//modules/frontend"
  version       = "~> 0.0.1"
  project_id    = var.project_id
  region        = "us-central1"
  name          = "frontend-lb-mig"
  url_map_input = module.lb-http-backend.backend_service_info
  network       = google_compute_network.default.name

}

module "instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 13.0"

  project_id           = var.project_id
  region               = "us-central1"
  source_image_project = "debian-cloud"
  source_image         = "debian-12"
  network              = google_compute_network.default.self_link
  subnetwork           = google_compute_subnetwork.default.self_link
  access_config        = [{ network_tier : "PREMIUM" }]
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix    = "instance-template"
  startup_script = <<EOF
    #! /bin/bash
    sudo apt-get update
    sudo apt-get install apache2 -y
    sudo a2ensite default-ssl
    sudo a2enmod ssl
    vm_hostname="$(curl -H "Metadata-Flavor:Google" \
    http://169.254.169.254/computeMetadata/v1/instance/name)"
    sudo echo "Page served from: $vm_hostname" | \
    tee /var/www/html/index.html
    sudo systemctl restart apache2
    EOF
  tags = [
    "load-balanced-backend"
  ]
}

module "mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "~> 13.0"
  instance_template = module.instance_template.self_link
  project_id        = var.project_id
  region            = "us-central1"
  hostname          = "mig-group"
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
}
