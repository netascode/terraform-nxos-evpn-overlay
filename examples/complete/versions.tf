terraform {
  required_version = ">= 1.1.0"

  required_providers {
    iosxe = {
      source  = "netascode/nxos"
      version = ">= 0.3.19"
    }
  }
}
