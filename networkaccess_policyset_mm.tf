## Issue a 10 second sleep timer before creating the Network Access Policy Set
## This is necessary to mitigate a race condition with the creation of the Network Device Groups and Allowed Protocols

resource "time_sleep" "mm_wait_10_seconds" {
  depends_on = [
    ise_allowed_protocols.mab_eaptls,
    ise_network_device_group.ndg_deployment_stage,
    ise_network_device_group.ndg_mm
  ]
  create_duration = "10s"
}

## Create the Policy Set for Wired Monitor Mode


resource "ise_network_access_policy_set" "ps_wired_mm" {
  depends_on = [
    time_sleep.mm_wait_10_seconds
  ]
  name                = var.ps_wired_mm_name
  description         = "Wired Monitor Mode"
  rank                = 0
  service_name        = ise_allowed_protocols.mab_eaptls.name
  state               = "enabled"
  is_proxy            = false
  condition_is_negate = false
  condition_type      = "ConditionAndBlock"
  children = [
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = "Radius"
      attribute_name  = "NAS-Port-Type"
      operator        = "equals"
      attribute_value = "Ethernet"
    },
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = "DEVICE"
      attribute_name  = ise_network_device_group.ndg_deployment_stage.root_group
      operator        = "equals"
      attribute_value = "Deployment Stage#Monitor Mode"
    },
  ]
}


## Get id for built-in Condition - Wired_802.1X

data "ise_network_access_condition" "wired_dot1x" {
  name = "Wired_802.1X"
}

## Get id for build-in Condition - Wired_MAB
data "ise_network_access_condition" "wired_mab" {
  name = "Wired_MAB"
}

## Create Wired_MM AuthC Policy - Dot1x EAP-TLS

resource "ise_network_access_authentication_rule" "mm_authc_eaptls" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_mm
  ]
  name                 = var.authc_policy_eaptls
  rank                 = 0
  state                = "enabled"
  identity_source_name = ise_identity_source_sequence.iss_ad_cert.name
  if_auth_fail         = "REJECT"
  if_process_fail      = "DROP"
  if_user_not_found    = "REJECT"
  policy_set_id        = ise_network_access_policy_set.ps_wired_mm.id
  default              = false
  condition_is_negate  = false
  condition_type       = "ConditionAndBlock"
  children = [
    {
      is_negate      = false
      condition_type = "ConditionReference"
      id             = data.ise_network_access_condition.wired_dot1x.id
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = "Network Access"
      attribute_name  = "EapAuthentication"
      operator        = "equals"
      attribute_value = "EAP-TLS"
    }
  ]
}

## Create Wired_MM AuthC Policy - MAB

resource "ise_network_access_authentication_rule" "mm_authc_mab" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_mm,
    ise_network_access_authentication_rule.mm_authc_eaptls
  ]
  name                 = var.authc_policy_mab
  rank                 = 1
  state                = "enabled"
  identity_source_name = "Internal Endpoints"
  if_auth_fail         = "REJECT"
  if_process_fail      = "DROP"
  if_user_not_found    = "CONTINUE"
  policy_set_id        = ise_network_access_policy_set.ps_wired_mm.id
  default              = false
  condition_is_negate  = false
  condition_type       = "ConditionReference"
  condition_id         = data.ise_network_access_condition.wired_mab.id
}

## Create Wired_MM AuthZ Policy Rule 1 - AD User

resource "ise_network_access_authorization_rule" "mm_authz_ad_user" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_mm,
    ise_active_directory_add_groups.ad_domain_groups
  ]
  policy_set_id = ise_network_access_policy_set.ps_wired_mm.id
  profiles = [
    ise_authorization_profile.mm_authz_ad_user.name
  ]
  default             = false
  name                = var.authz_policy_ad_user
  rank                = 0
  state               = "enabled"
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    is_negate       = false
    condition_type  = "ConditionAttributes"
    dictionary_name = "Network Access"
    attribute_name  = "EapAuthentication"
    operator        = "equals"
    attribute_value = "EAP-TLS"
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.domain_users.groups[0].name
    }
  ]
  security_group = ise_trustsec_security_group.sgt_corp_user.name
}

## Create Wired_MM AuthZ Policy Rule 2 - AD Computer

resource "ise_network_access_authorization_rule" "mm_authz_ad_computer" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_mm,
    ise_network_access_authorization_rule.mm_authz_ad_user,
    ise_active_directory_add_groups.ad_domain_groups
  ]
  policy_set_id = ise_network_access_policy_set.ps_wired_mm.id
  profiles = [
    ise_authorization_profile.mm_authz_ad_computer.name
  ]
  default             = false
  name                = var.authz_policy_ad_computer
  rank                = 1
  state               = "enabled"
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    is_negate       = false
    condition_type  = "ConditionAttributes"
    dictionary_name = "Network Access"
    attribute_name  = "EapAuthentication"
    operator        = "equals"
    attribute_value = "EAP-TLS"
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.domain_computers.groups[0].name
    }
  ]
  security_group = ise_trustsec_security_group.sgt_corp_user.name
}

## Get ID for Default AuthZ Policy rule

data "ise_network_access_policy_set" "ps_wired_mm" {
  name = ise_network_access_policy_set.ps_wired_mm.name
}

data "ise_network_access_authorization_rule" "mm_authz_default" {
  depends_on = [
    ise_network_access_authorization_rule.mm_authz_ad_user,
    ise_network_access_authorization_rule.mm_authz_ad_computer
  ]
  policy_set_id = data.ise_network_access_policy_set.ps_wired_mm.id
  name          = "Default"
}

/*
## Update Wired_MM Default AuthZ Policy Rule to replace 'DenyAccess' with 'MM-AuthZ-Default' AuthZ Profile -- ISSUE OPENED

resource "ise_network_access_authorization_rule" "mm_authz_default" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_mm,
    data.ise_network_access_policy_set.ps_wired_mm,
    data.ise_network_access_authorization_rule.mm_authz_default
   ]
  policy_set_id = data.ise_network_access_policy_set.ps_wired_mm.id
  name          = "Default"
  default       = true
  rank          = data.ise_network_access_authorization_rule.mm_authz_default.rank
  state         = "enabled"
  profiles = [
    ise_authorization_profile.mm_authz_default.name
  ]
}

import {
  to = ise_network_access_authorization_rule.mm_authz_default
  id = "${data.ise_network_access_policy_set.ps_wired_mm.id},${data.ise_network_access_authorization_rule.mm_authz_default.id}"
}
*/