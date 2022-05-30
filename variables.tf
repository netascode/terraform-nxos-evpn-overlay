variable "leafs" {
  description = "List of leaf device names. This list of devices must also be added to the provider configuration."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "spines" {
  description = "List of spine device names. This list of devices must also be added to the provider configuration."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "underlay_loopback_id" {
  description = "Loopback ID used for underlay routing and BGP."
  type        = number
  default     = 0
  nullable    = false

  validation {
    condition     = var.underlay_loopback_id >= 0 && var.underlay_loopback_id <= 2147483647
    error_message = "`Must be a value between `0` and `2147483647`."
  }
}

variable "underlay_loopbacks" {
  description = "List of underlay loopback interfaces. These loopbacks are assumed to be pre-configured on every device."
  type = list(object({
    device       = string
    ipv4_address = string
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for v in var.underlay_loopbacks : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", v.ipv4_address))
    ])
    error_message = "`ipv4_address`: Allowed formats are: `192.168.1.1`."
  }
}

variable "vtep_loopback_id" {
  description = "Loopback ID used for VTEP loopbacks. These loopbacks are assumed to be pre-configured on all leafs."
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition     = var.vtep_loopback_id >= 0 && var.vtep_loopback_id <= 2147483647
    error_message = "`Must be a value between `0` and `2147483647`."
  }
}

variable "bgp_asn" {
  description = "BGP AS number."
  type        = number
  default     = 65000
  nullable    = false

  validation {
    condition     = var.bgp_asn >= 0 && var.bgp_asn <= 4294967295
    error_message = "`Must be a value between `0` and `4294967295`."
  }
}

variable "l3_services" {
  description = "List of L3 services. `name` is the VRF name. `id` is the core-facing SVI VLAN ID. If no `ipv4_multicast_group` is specified, ingress replication will be used."
  type = list(object({
    name = string
    id   = number
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for s in var.l3_services : s.id >= 1 && s.id <= 4094
    ])
    error_message = "`id`: Must be a value between `1` and `4094`."
  }
}


variable "l2_services" {
  description = "List of L2 services. `id` is the access VLAN ID. If no `ipv4_multicast_group` is specified, ingress replication will be used."
  type = list(object({
    name                 = string
    id                   = number
    ipv4_multicast_group = optional(string)
    l3_service           = optional(string)
    ipv4_address         = optional(string)
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for s in var.l2_services : s.id >= 1 && s.id <= 4094
    ])
    error_message = "`id`: Must be a value between `1` and `4094`."
  }

  validation {
    condition = alltrue([
      for s in var.l2_services : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", s.ipv4_multicast_group)) || s.ipv4_multicast_group == null
    ])
    error_message = "`ipv4_multicast_group`: Allowed formats are: `225.0.0.1`."
  }

  validation {
    condition = alltrue([
      for s in var.l2_services : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", s.ipv4_address)) || s.ipv4_address == null
    ])
    error_message = "`ipv4_address`: Allowed formats are: `10.1.1.1/24`."
  }
}
