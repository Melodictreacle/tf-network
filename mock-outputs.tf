# ==============================================================
# mock-outputs.tf - Mock Test Output Info
# ==============================================================

output "test_vms" {
  description = "The DHCP IPs of the 3 test VMs (before static Netplan takes effect)"
  value = {
    "1_website (VulnCorp)"    = vmworkstation_vm.website.id
    "2_host_g (Storage/DB)"   = vmworkstation_vm.host_g.id
    "3_host_f (OwnCloud)"     = vmworkstation_vm.host_f.id
  }
}

output "expected_static_ips" {
  description = "The expected IP addresses after provisioning finishes running in the background."
  value = <<-IPS

    ┌──────────────────────────────────────────────────┐
    │          EXPECTED IPs AFTER PROVISIONING         │
    ├──────────┬────────────┬──────────────┬───────────┤
    │  Host    │  DMZ       │  net_1       │  net_4    │
    │          │  10.10.0.x │  10.10.1.x   │ 10.10.4.x │
    ├──────────┼────────────┼──────────────┼───────────┤
    │ Website  │  .2        │     —        │     —     │
    │ Host G   │   —        │    —         │   .17     │
    │ Host F   │   —        │   .16        │   .16     │
    └──────────┴────────────┴──────────────┴───────────┘
  IPS
}
