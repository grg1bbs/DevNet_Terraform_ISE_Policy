## Issue a 10 second sleep timer before creating the Network Access Policy Set
## This is necessary to mitigate a race condition with the creation of the Network Device Groups and Allowed Protocols

resource "time_sleep" "wireless_wait_10_seconds" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_mm,
    ise_network_access_policy_set.ps_wired_lim
  ]
  create_duration = "10s"
}

## Get the id for the built-in condition - Wireless_802.1X

data "ise_network_access_condition" "wireless_dot1x" {
  name = "Wireless_802.1X"
}

## Create Policy Set for Corp Wireless

resource "ise_network_access_policy_set" "ps_wireless_secure" {
  depends_on = [
    time_sleep.wireless_wait_10_seconds
  ]
  name                = var.ps_corp_wireless_name
  description         = "Corp Wireless"
  rank                = 2
  is_proxy            = false
  service_name        = "EAP-TLS"
  state               = "enabled"
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [
    {
      condition_type = "ConditionReference"
      is_negate      = false
      id             = data.ise_network_access_condition.wireless_dot1x.id
    },
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = "Radius"
      attribute_name  = "Called-Station-ID"
      operator        = "endsWith"
      attribute_value = var.corp_wireless_ssid
  }]
}

## Create Corp Wireless AuthC Policy - Dot1x TEAP

resource "ise_network_access_authentication_rule" "authc_wireless_teap" {
  depends_on = [
    ise_network_access_policy_set.ps_wireless_secure
  ]
  name                 = var.authc_policy_teap
  rank                 = 0
  state                = "enabled"
  identity_source_name = ise_identity_source_sequence.iss_ad_cert.name
  if_auth_fail         = "REJECT"
  if_process_fail      = "DROP"
  if_user_not_found    = "REJECT"
  policy_set_id        = ise_network_access_policy_set.ps_wireless_secure.id
  default              = false
  condition_type       = "ConditionAndBlock"
  condition_is_negate  = false
  children = [
    {
      is_negate      = false
      condition_type = "ConditionReference"
      id             = data.ise_network_access_condition.wireless_dot1x.id
    },
    {
      condition_type  = "ConditionAttributes"
      dictionary_name = "Network Access"
      attribute_name  = "EapTunnel"
      operator        = "equals"
      attribute_value = "TEAP"
      is_negate       = false
    }
  ]
}

## Create Corp Wireless AuthC Policy - Dot1x EAP-TLS

resource "ise_network_access_authentication_rule" "authc_wireless_eaptls" {
  depends_on = [
    ise_network_access_policy_set.ps_wireless_secure
  ]
  name                 = var.authc_policy_eaptls
  rank                 = 1
  state                = "enabled"
  identity_source_name = ise_identity_source_sequence.iss_ad_cert.name
  if_auth_fail         = "REJECT"
  if_process_fail      = "DROP"
  if_user_not_found    = "REJECT"
  policy_set_id        = ise_network_access_policy_set.ps_wireless_secure.id
  default              = false
  condition_type       = "ConditionAndBlock"
  condition_is_negate  = false
  children = [
    {
      is_negate      = false
      condition_type = "ConditionReference"
      id             = data.ise_network_access_condition.wireless_dot1x.id
    },
    {
      condition_type  = "ConditionAttributes"
      dictionary_name = "Network Access"
      attribute_name  = "EapAuthentication"
      operator        = "equals"
      attribute_value = "EAP-TLS"
      is_negate       = false
    }
  ]
}

## Create Corp Wireless AuthZ Policy Rule 1 - AD User TEAP

resource "ise_network_access_authorization_rule" "authz_wireless_ad_user_teap" {
  depends_on = [
    ise_network_access_policy_set.ps_wireless_secure,
    ise_active_directory_add_groups.ad_domain_groups
  ]
  policy_set_id = ise_network_access_policy_set.ps_wireless_secure.id
  profiles = [
    ise_authorization_profile.authz_wireless_ad_user.name
  ]
  default             = false
  name                = "${var.authz_policy_ad_user} EAP Chained"
  rank                = 0
  state               = "enabled"
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    is_negate       = false
    condition_type  = "ConditionAttributes"
    dictionary_name = "Network Access"
    attribute_name  = "EapTunnel"
    operator        = "equals"
    attribute_value = "TEAP"
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.domain_users.groups[0].name
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.domain_computers.groups[0].name
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = "Network Access"
      attribute_name  = "EapChainingResult"
      operator        = "equals"
      attribute_value = "User and machine both succeeded"
    }
  ]
  security_group = ise_trustsec_security_group.sgt_corp_user.name
}

## Create Corp Wireless AuthZ Policy Rule 2 - AD Computer TEAP

resource "ise_network_access_authorization_rule" "authz_wireless_ad_computer_teap" {
  depends_on = [
    ise_network_access_policy_set.ps_wireless_secure,
    ise_network_access_authorization_rule.authz_wireless_ad_user_teap,
    ise_active_directory_add_groups.ad_domain_groups
  ]
  policy_set_id = ise_network_access_policy_set.ps_wireless_secure.id
  profiles = [
    ise_authorization_profile.authz_wireless_ad_computer.name
  ]
  default             = false
  name                = "${var.authz_policy_ad_computer} TEAP"
  rank                = 1
  state               = "enabled"
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    is_negate       = false
    condition_type  = "ConditionAttributes"
    dictionary_name = "Network Access"
    attribute_name  = "EapTunnel"
    operator        = "equals"
    attribute_value = "TEAP"
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.domain_computers.groups[0].name
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = "Network Access"
      attribute_name  = "EapChainingResult"
      operator        = "equals"
      attribute_value = "User failed and machine succeeded"
    }
  ]
  security_group = ise_trustsec_security_group.sgt_corp_user.name
}

## Create Corp Wireless AuthZ Policy Rule 3 - AD User EAP-TLS

resource "ise_network_access_authorization_rule" "authz_wireless_ad_user_eaptls" {
  depends_on = [
    ise_network_access_policy_set.ps_wireless_secure,
    ise_active_directory_add_groups.ad_domain_groups,
    data.ise_active_directory_groups_by_domain.domain_users
  ]
  policy_set_id = ise_network_access_policy_set.ps_wireless_secure.id
  profiles = [
    ise_authorization_profile.authz_wireless_ad_user.name
  ]
  default             = false
  name                = "${var.authz_policy_ad_user} EAP-TLS"
  rank                = 2
  state               = "enabled"
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    is_negate      = false
    condition_type = "ConditionReference"
    id             = data.ise_network_access_condition.wireless_dot1x.id
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

## Create Wired_MM AuthZ Policy Rule 2 - AD Computer EAP-TLS

resource "ise_network_access_authorization_rule" "authz_wireless_ad_computer_eaptls" {
  depends_on = [
    ise_network_access_policy_set.ps_wireless_secure,
    ise_network_access_authorization_rule.authz_wireless_ad_user_teap,
    ise_network_access_authorization_rule.authz_wireless_ad_computer_teap,
    ise_network_access_authorization_rule.authz_wireless_ad_user_eaptls,
    ise_active_directory_add_groups.ad_domain_groups,
    data.ise_active_directory_groups_by_domain.domain_computers
  ]
  policy_set_id = ise_network_access_policy_set.ps_wireless_secure.id
  profiles = [
    ise_authorization_profile.authz_wireless_ad_computer.name
  ]
  default             = false
  name                = "${var.authz_policy_ad_computer} EAP-TLS"
  rank                = 3
  state               = "enabled"
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    is_negate      = false
    condition_type = "ConditionReference"
    id             = data.ise_network_access_condition.wireless_dot1x.id
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