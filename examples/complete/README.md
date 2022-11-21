<!-- BEGIN_TF_DOCS -->
# NX-OS EVPN Overlay Example

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example will create resources. Resources can be destroyed with `terraform destroy`.

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
<!-- END_TF_DOCS -->