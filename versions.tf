terraform {
  required_version = ">= 1.3.0"

  required_providers {
    nxos = {
      source  = "CiscoDevNet/nxos"
      version = ">= 0.5.0"
    }
  }
}
