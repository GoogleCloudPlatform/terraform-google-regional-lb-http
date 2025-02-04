# Upgrading to v0.3.0

The v0.3.0 for `modules/frontend` release contains backwards-incompatible changes.

## Changes in v0.3.0

### Conditional REGIONAL_MANAGED_PROXY subnet creation

  In previous release `v0.2.0`, the REGIONAL_MANAGED_PROXY subnetwork creation was always happening as part of `modules/frontend`. In the release `v0.3.0`, the subnet creation is conditional and is based on `create_proxy_only_subnet` variable.
  Users need to explicitly set `create_proxy_only_subnet` to `true` for creating REGIONAL_MANAGED_PROXY subnetwork.

```diff
module "lb-http-frontend" {
  source                   = "GoogleCloudPlatform/regional-lb-http/google//modules/frontend"
  version                  = "~> 0.3.0"
  project_id               = var.project_id
  region                   = var.region
  name                     = "frontend-lb"
  url_map_input            = module.lb-http-backend.backend_service_info
  network                  = google_compute_network.default.name
+ create_proxy_only_subnet = true
}
```
