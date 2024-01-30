## Create Security Groups for TrustSec -- Uses static values to work around idempotence issue with auto-generated value -1

resource "ise_trustsec_security_group" "sgt_corp_user" {
  name              = var.sgt_corp_user
  description       = "Corporate Users"
  value             = 101
  propogate_to_apic = false
  is_read_only      = false
}

