# HTTP Regional Load Balancer Example - GCE MIG

This example creates a regional HTTP forwarding rule to forward traffic to GCE manager instance group. The `google_compute_region_backend_service` and its dependencies are created as part of `backend` module.
The forwarding rules and its dependecies are created as part of `frontend` modules.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| external\_ip | The IP address of the forwarding rule |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
