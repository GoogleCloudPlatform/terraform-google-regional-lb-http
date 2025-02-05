# HTTP Regional Load balancer frontend module
This module creates `HTTP(S) forwarding rule` and its dependencies. This modules doesn't create `google_compute_region_backend_service` which can be created by using `modules/frontend`. The separation of the modules makes it easier for creating backend and frontend resources independent of each other. The logical separation helps in improved maintainability.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| address | Existing IPv4 address to use (the actual IP address value) | `string` | `null` | no |
| certificate | Content of the SSL certificate. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true` | `string` | `null` | no |
| create\_address | Create a new global IPv4 address | `bool` | `true` | no |
| create\_ipv6\_address | Allocate a new IPv6 address. Conflicts with "ipv6\_address" - if both specified, "create\_ipv6\_address" takes precedence. | `bool` | `false` | no |
| create\_proxy\_only\_subnet | Create a REGIONAL\_MANAGED\_PROXY subnetwork in the provide VPC network. | `bool` | `false` | no |
| create\_ssl\_certificate | If `true`, Create certificate using `private_key/certificate` | `bool` | `false` | no |
| create\_url\_map | Set to `false` if url\_map\_resource\_uri variable is provided. | `bool` | `true` | no |
| enable\_ipv6 | Enable IPv6 address on the CDN load-balancer | `bool` | `false` | no |
| http\_forward | Set to `false` to disable HTTP port 80 forward | `bool` | `true` | no |
| http\_keep\_alive\_timeout\_sec | Specifies how long to keep a connection open, after completing a response, while there is no matching traffic (in seconds). | `number` | `null` | no |
| http\_port | The port for the HTTP load balancer | `number` | `80` | no |
| https\_port | The port for the HTTPS load balancer | `number` | `443` | no |
| https\_redirect | Set to `true` to enable https redirect on the lb. | `bool` | `false` | no |
| ipv6\_address | An existing IPv6 address to use (the actual IP address value) | `string` | `null` | no |
| labels | The labels to attach to resources created by this module | `map(string)` | `{}` | no |
| load\_balancing\_scheme | Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL\_MANAGED for Envoy-based load balancer, and INTERNAL\_SELF\_MANAGED for traffic director) | `string` | `"EXTERNAL_MANAGED"` | no |
| managed\_ssl\_certificate\_domains | Create Google-managed SSL certificates for specified domains. Requires `ssl` to be set to `true` | `list(string)` | `[]` | no |
| name | Name for the forwarding rule and prefix for supporting resources | `string` | n/a | yes |
| network | VPC network for the forwarding rule. It should not be default. The VPC network should have only one REGIONAL\_MANAGED\_PROXY subnetwork in the same region as of this regional load balancer. Please go to the subnets tab of your VPC network and check if a REGIONAL\_MANAGED\_PROXY subnet exists under `Reserved proxy-only subnets for load balancing` section. If the REGIONAL\_MANAGED\_PROXY doesn't exists, set create\_proxy\_only\_subnet parameter to provision it as part of this component deployment. | `string` | n/a | yes |
| private\_key | Content of the private SSL key. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true` | `string` | `null` | no |
| project\_id | The project to deploy load balancer frontend resources.. | `string` | n/a | yes |
| proxy\_only\_subnet\_ip | ip\_cidr\_range for creating REGIONAL\_MANAGED\_PROXY subnetwork in the provided VPC network. | `string` | `"10.129.0.0/23"` | no |
| random\_certificate\_suffix | Bool to enable/disable random certificate name generation. Set and keep this to true if you need to change the SSL cert. | `bool` | `false` | no |
| region | The region where the load balancer will be created | `string` | n/a | yes |
| server\_tls\_policy | The resource URL for the server TLS policy to associate with the https proxy service | `string` | `null` | no |
| ssl | Set to `true` to enable SSL support. If `true` then at least one of these are required: 1) `ssl_certificates` OR 2) `create_ssl_certificate` set to `true` and `private_key/certificate` OR  3) `managed_ssl_certificate_domains`, OR 4) `certificate_map` | `bool` | `false` | no |
| ssl\_certificates | SSL cert self\_link list. Requires `ssl` to be set to `true` | `list(string)` | `[]` | no |
| ssl\_policy | Selfink to SSL Policy | `string` | `null` | no |
| url\_map\_input | List of host, path and backend service for creating url\_map when create\_url\_map is set to true. | <pre>list(object({<br>    host            = string<br>    path            = string<br>    backend_service = string<br>  }))</pre> | `[]` | no |
| url\_map\_resource\_uri | The url\_map resource to use. This is the resource uri of the url map created out of band. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| apphub\_service\_uri | A list of all App Hub service URIs, including HTTP, HTTPS, and IPv6 versions. |
| external\_ip | The external IPv4 assigned to the fowarding rule. |
| http\_proxy | The HTTP proxy used by this module. |
| https\_proxy | The HTTPS proxy used by this module. |
| ssl\_certificate\_created | The SSL certificate create from key/pem |
| url\_map | The URL map used by this load balancer frontend. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
