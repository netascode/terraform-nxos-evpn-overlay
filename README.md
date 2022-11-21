<!-- BEGIN_TF_DOCS -->
[![Tests](https://github.com/netascode/terraform-nxos-evpn-ospf-underlay/actions/workflows/test.yml/badge.svg)](https://github.com/netascode/terraform-nxos-evpn-ospf-underlay/actions/workflows/test.yml)

# Terraform Cisco NX-OS EVPN Overlay Module

This module can manage a Cisco Nexus 9000 EVPN fabric overlay.

The following assumptions have been made:

- A working underlay network including VTEP loopbacks is pre-configured (e.g., using the [EVPN OSPF Underlay Terraform Module](https://registry.terraform.io/modules/netascode/evpn-ospf-underlay/nxos))
- A single BGP AS is used for all devices with spines acting as route reflectors
- All services will be provisioned on all leafs
- No L2 or L3 access interfaces will be provisioned
- A `l3_service` refers to a single VRF and L3 VNI
- A `l2_service` refers to a single L2 VNI with or without an SVI (VLAN interface)
- An SVI (VLAN interface) will be provisioned as an anycast gateway on all leafs
- If no `ipv4_multicast_group` is configured ingress replication will be used

## Examples

```hcl
module "nxos_evpn_overlay" {
  source  = "netascode/evpn-overlay/nxos"
  version = ">= 0.2.0"

  leafs                = ["LEAF-1", "LEAF-2"]
  spines               = ["SPINE-1", "SPINE-2"]
  underlay_loopback_id = 0

  underlay_loopbacks = [
    {
      device       = "SPINE-1",
      ipv4_address = "10.1.100.1"
    },
    {
      device       = "SPINE-2",
      ipv4_address = "10.1.100.2"
    },
    {
      device       = "LEAF-1",
      ipv4_address = "10.1.100.3"
    },
    {
      device       = "LEAF-2",
      ipv4_address = "10.1.100.4"
    }
  ]

  vtep_loopback_id = 1
  bgp_asn          = 65000

  l3_services = [
    {
      name = "GREEN"
      id   = 1000
    },
    {
      name = "BLUE"
      id   = 1010
    }
  ]

  l2_services = [
    {
      name                 = "L2_101"
      id                   = 101
      ipv4_multicast_group = "225.0.0.101"
    },
    {
      name = "L2_102"
      id   = 102
    },
    {
      name                 = "GREEN_1001"
      id                   = 1001
      ipv4_multicast_group = "225.0.1.1"
      l3_service           = "GREEN"
      ipv4_address         = "172.16.1.1/24"
    },
    {
      name         = "BLUE_1011"
      id           = 1011
      l3_service   = "BLUE"
      ipv4_address = "172.17.1.1/24"
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_nxos"></a> [nxos](#requirement\_nxos) | >= 0.3.19 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_nxos"></a> [nxos](#provider\_nxos) | >= 0.3.19 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_leafs"></a> [leafs](#input\_leafs) | List of leaf device names. This list of devices must also be added to the provider configuration. | `set(string)` | `[]` | no |
| <a name="input_spines"></a> [spines](#input\_spines) | List of spine device names. This list of devices must also be added to the provider configuration. | `set(string)` | `[]` | no |
| <a name="input_underlay_loopback_id"></a> [underlay\_loopback\_id](#input\_underlay\_loopback\_id) | Loopback ID used for underlay routing and BGP. | `number` | `0` | no |
| <a name="input_underlay_loopbacks"></a> [underlay\_loopbacks](#input\_underlay\_loopbacks) | List of underlay loopback interfaces. These loopbacks are assumed to be pre-configured on every device. | <pre>list(object({<br>    device       = string<br>    ipv4_address = string<br>  }))</pre> | `[]` | no |
| <a name="input_vtep_loopback_id"></a> [vtep\_loopback\_id](#input\_vtep\_loopback\_id) | Loopback ID used for VTEP loopbacks. These loopbacks are assumed to be pre-configured on all leafs. | `number` | `1` | no |
| <a name="input_bgp_asn"></a> [bgp\_asn](#input\_bgp\_asn) | BGP AS number. | `number` | `65000` | no |
| <a name="input_l3_services"></a> [l3\_services](#input\_l3\_services) | List of L3 services. `name` is the VRF name. `id` is the core-facing SVI VLAN ID. If no `ipv4_multicast_group` is specified, ingress replication will be used. | <pre>list(object({<br>    name = string<br>    id   = number<br>  }))</pre> | `[]` | no |
| <a name="input_l2_services"></a> [l2\_services](#input\_l2\_services) | List of L2 services. `id` is the access VLAN ID. If no `ipv4_multicast_group` is specified, ingress replication will be used. | <pre>list(object({<br>    name                 = string<br>    id                   = number<br>    ipv4_multicast_group = optional(string)<br>    l3_service           = optional(string)<br>    ipv4_address         = optional(string)<br>  }))</pre> | `[]` | no |

## Outputs

No outputs.

## Resources

| Name | Type |
|------|------|
| [nxos_bridge_domain.l2_vlan](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/bridge_domain) | resource |
| [nxos_bridge_domain.l3_vlan](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/bridge_domain) | resource |
<!-- END_TF_DOCS -->