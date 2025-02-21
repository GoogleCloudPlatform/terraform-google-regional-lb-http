# HTTP Internal Regional Load Balancer Example

This example creates an internal regional HTTP forwarding rule to forward traffic to cloud run service. The `google_compute_region_backend_service` and its dependencies are created as part of `backend` module.
The forwarding rules and its dependecies are created as part of `frontend` modules.

In this example,
* One internal regional load balancer is created which doesn't have any external_ip address.
* One external regional load balancer is created which talks a frontend cloud run. The service redirects traffic to the internal load balancer.

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
