# Cross-Regional Failover with RXLB Example

This example demonstrates how to configure a regional HTTP Load Balancer with **cross-regional failover** support using the `terraform-google-regional-lb-http` module.

The setup provisions regional backend services in two regions and configures RXLB (Regional Cross-regional Load Balancing) so that if one region becomes unavailable, traffic automatically fails over to the other region.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Inputs

| Name       | Description                              | Type     | Default         | Required |
| ---------- | ---------------------------------------- | -------- | --------------- | :------: |
| project_id | The project ID where resources will live | `string` | n/a             |    yes   |
| region1    | The primary region for backend services  | `string` | `"us-central1"` |    no    |
| region2    | The secondary region for failover        | `string` | `"us-east1"`    |    no    |

## Outputs

| Name        | Description                                         |
| ----------- | --------------------------------------------------- |
| external_ip | The external IP address of the RXLB forwarding rule |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## How it works

* **Backend module**: Creates `google_compute_region_backend_service` resources and dependencies in multiple regions.
* **Frontend module**: Creates the HTTP forwarding rule, target proxy, and URL map with RXLB failover configuration.

When deployed, users can send traffic to the external IP, and if the primary region backends are unavailable, traffic is routed to the secondary region.

---
