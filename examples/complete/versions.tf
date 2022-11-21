terraform {
  required_version = ">= 1.3.0"

  required_providers {
    iosxe = {
      source  = "netascode/nxos"
      version = ">= 0.3.19"
    }
  }
}
