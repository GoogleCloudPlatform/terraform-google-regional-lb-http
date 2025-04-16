# HTTP Regional Load Balancer Example - GCE MIG

This example creates a regional HTTP forwarding rule to forward traffic to GCE managed instance group. The `google_compute_region_backend_service` and its dependencies are created as part of `backend` module.
The forwarding rules and its dependecies are created as part of `frontend` modules.
The forwarding rule is INTERNAL_MANAGED and can not be accessed on open internet. This example also creates a publicly accessible cloud-run service to access the internal load balancer using the internal ip address of the forwarding rule.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| frontend\_service\_uri | The IP address of the forwarding rule |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
