# HTTP Regional Load Balancer Example - Separate modules for creating HTTP load balancer frontend and backend resources

This example creates a regional HTTP forwarding rule to forward traffic to cloud run service. The `google_compute_region_backend_service` and its dependencies are created as part of `backend` module.
The forwarding rules and its dependecies are created as part of `frontend` modules.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | n/a | `string` | n/a | yes |
| region | n/a | `string` | `"us-central1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| external\_ip | The IP address of the forwarding rule |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
