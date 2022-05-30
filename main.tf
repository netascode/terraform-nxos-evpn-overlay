locals {
  all                  = setunion(var.leafs, var.spines)
  leaf_l2_services     = { for l in setproduct(var.leafs, var.l2_services) : "${l[0]}/${l[1].id}" => l }
  leaf_l2_services_svi = { for l in setproduct(var.leafs, var.l2_services) : "${l[0]}/${l[1].id}" => l if l[1].ipv4_address != null }
  leaf_l3_services     = { for l in setproduct(var.leafs, var.l3_services) : "${l[0]}/${l[1].id}" => l }
}

module "nxos_bgp_leaf" {
  source  = "netascode/bgp/nxos"
  version = ">= 0.1.0"

  for_each = var.leafs

  device = each.value

  asn = var.bgp_asn
  template_peers = [
    {
      name             = "SPINE-PEERS"
      asn              = var.bgp_asn
      source_interface = "lo${var.underlay_loopback_id}"
      address_families = [
        {
          address_family          = "l2vpn_evpn"
          send_community_standard = true
          send_community_extended = true
        }
      ]
    }
  ]
  vrfs = [
    {
      vrf       = "default"
      router_id = [for l in var.underlay_loopbacks : l.ipv4_address if each.value == l.device][0]
      neighbors = [for spine in var.spines :
        {
          ip           = [for l in var.underlay_loopbacks : l.ipv4_address if spine == l.device][0]
          inherit_peer = "SPINE-PEERS"
        }
      ]
    }
  ]
}

module "nxos_bgp_spine" {
  source  = "netascode/bgp/nxos"
  version = ">= 0.1.0"

  for_each = var.spines

  device = each.value

  asn = var.bgp_asn
  template_peers = [
    {
      name             = "LEAF-PEERS"
      asn              = var.bgp_asn
      source_interface = "lo${var.underlay_loopback_id}"
      address_families = [
        {
          address_family          = "l2vpn_evpn"
          send_community_standard = true
          send_community_extended = true
          route_reflector_client  = true
        }
      ]
    }
  ]
  vrfs = [
    {
      vrf       = "default"
      router_id = [for l in var.underlay_loopbacks : l.ipv4_address if each.value == l.device][0]
      neighbors = [for leaf in var.leafs :
        {
          ip           = [for l in var.underlay_loopbacks : l.ipv4_address if leaf == l.device][0]
          inherit_peer = "LEAF-PEERS"
        }
      ]
    }
  ]
}

module "nxos_vrf" {
  source  = "netascode/vrf/nxos"
  version = ">= 0.1.0"

  for_each = local.leaf_l3_services

  device              = each.value[0]
  name                = each.value[1].name
  vni                 = each.value[1].id + 10000
  route_distinguisher = "auto"
  address_families = [
    {
      address_family           = "ipv4_unicast"
      route_target_import      = ["${var.bgp_asn}:${each.value[1].id + 10000}"]
      route_target_export      = ["${var.bgp_asn}:${each.value[1].id + 10000}"]
      route_target_import_evpn = ["${var.bgp_asn}:${each.value[1].id + 10000}"]
      route_target_export_evpn = ["${var.bgp_asn}:${each.value[1].id + 10000}"]
    }
  ]
}

resource "nxos_bridge_domain" "l3_vlan" {
  for_each = local.leaf_l3_services

  device       = each.value[0]
  fabric_encap = "vlan-${each.value[1].id}"
  access_encap = "vxlan-${each.value[1].id + 10000}"
  name         = each.value[1].name
}

module "nxos_interface_vlan_l3" {
  source  = "netascode/interface-vlan/nxos"
  version = ">= 0.1.0"

  for_each = local.leaf_l3_services

  device      = each.value[0]
  id          = each.value[1].id
  admin_state = true
  vrf         = each.value[1].name
  ip_forward  = true
}

module "nxos_evpn" {
  source  = "netascode/evpn/nxos"
  version = ">= 0.1.0"

  for_each = var.leafs

  device = each.value
  vnis = [for l2 in var.l2_services :
    {
      vni                 = l2.id + 10000
      route_distinguisher = "auto"
      route_target_import = ["${var.bgp_asn}:${l2.id + 10000}"]
      route_target_export = ["${var.bgp_asn}:${l2.id + 10000}"]
    }
  ]
}

resource "nxos_bridge_domain" "l2_vlan" {
  for_each = local.leaf_l2_services

  device       = each.value[0]
  fabric_encap = "vlan-${each.value[1].id}"
  access_encap = "vxlan-${each.value[1].id + 10000}"
  name         = each.value[1].name
}

module "nxos_interface_vlan_l2" {
  source  = "netascode/interface-vlan/nxos"
  version = ">= 0.1.0"

  for_each = local.leaf_l2_services_svi

  device       = each.value[0]
  id           = each.value[1].id
  admin_state  = true
  vrf          = each.value[1].l3_service
  ipv4_address = each.value[1].ipv4_address
}

module "nxos_fabric_forwarding" {
  source  = "netascode/fabric-forwarding/nxos"
  version = ">= 0.1.0"

  for_each = var.leafs

  device              = each.value
  anycast_gateway_mac = "20:20:00:00:10:12"
  vlan_interfaces = [for l2 in var.l2_services :
    {
      id = l2.id
    } if l2.ipv4_address != null
  ]

  depends_on = [module.nxos_interface_vlan_l2]
}

module "nxos_interface_nve" {
  source  = "netascode/interface-nve/nxos"
  version = ">= 0.1.0"

  for_each = var.leafs

  device                     = each.value
  admin_state                = true
  advertise_virtual_mac      = true
  host_reachability_protocol = "bgp"
  source_interface           = "lo${var.vtep_loopback_id}"
  vnis = concat([for l3 in var.l3_services :
    {
      vni           = l3.id + 10000
      associate_vrf = true
    }
    ],
    [for l2 in var.l2_services :
      {
        vni                          = l2.id + 10000
        multicast_group              = l2.ipv4_multicast_group
        ingress_replication_protocol = l2.ipv4_multicast_group == null ? "bgp" : null
      }
  ])
}
