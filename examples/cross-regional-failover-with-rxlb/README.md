# Cross-Regional Failover with RXLB Example

This example demonstrates how to configure a regional HTTP Load Balancer with **cross-regional failover** support using the `terraform-google-regional-lb-http` module.

The setup provisions regional backend services in two regions and configures RXLB (Regional Cross-regional Load Balancing) so that if one region becomes unavailable, traffic automatically fails over to the other region.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create\_public\_zone | Whether to create a new public managed zone | `bool` | `true` | no |
| enable\_dns\_records | Whether to create DNS records | `bool` | `true` | no |
| instance\_image | Image for test instances | `string` | `"projects/debian-cloud/global/images/family/debian-11"` | no |
| instance\_machine\_type | Machine type | `string` | `"e2-medium"` | no |
| proxy\_subnet\_cidrs | Proxy-only subnet CIDRs per region | `map(string)` | <pre>{<br>  "us-central1": "10.30.0.0/24",<br>  "us-east1": "10.40.0.0/24"<br>}</pre> | no |
| public\_zone\_name | Name of an existing public managed zone (used if create\_public\_zone=false) | `string` | `"public-example-zone"` | no |
| region\_to\_zone | Region -> zone mapping for MIGs | `map(string)` | <pre>{<br>  "us-central1": "us-central1-a",<br>  "us-east1": "us-east1-b"<br>}</pre> | no |
| regional\_hostname | DNS hostname used for certificates and DNS records | `string` | `"regional.example.com"` | no |
| regions | Regions where to create regional ALBs | `map(string)` | <pre>{<br>  "us-central1": "us-central1",<br>  "us-east1": "us-east1"<br>}</pre> | no |
| target\_size | Number of VMs per MIG | `number` | `2` | no |
| vm\_subnet\_cidrs | VM subnet CIDRs per region | `map(string)` | <pre>{<br>  "us-central1": "10.10.0.0/24",<br>  "us-east1": "10.20.0.0/24"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| regional\_ips | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## How it works

* **Backend module**: Creates `google_compute_region_backend_service` resources and dependencies in multiple regions.
* **Frontend module**: Creates the HTTP forwarding rule, target proxy, and URL map with RXLB failover configuration.

When deployed, users can send traffic to the external IP, and if the primary region backends are unavailable, traffic is routed to the secondary region.

---
