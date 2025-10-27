output "regional_ips" {
  value = { for k, a in google_compute_address.addr : k => a.address }
}
