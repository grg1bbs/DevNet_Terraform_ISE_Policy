
## Create Allowed Protocols Lists

resource "ise_allowed_protocols" "mab_dot1x" {
  name                         = "MAB_Dot1x"
  description                  = "MAB, EAP-TLS, and TEAP protocols"
  process_host_lookup          = true
  allow_pap_ascii              = false
  allow_chap                   = false
  allow_ms_chap_v1             = false
  allow_ms_chap_v2             = false
  allow_eap_md5                = false
  allow_eap_tls                = true
  allow_leap                   = false
  allow_peap                   = false
  allow_eap_fast               = false
  allow_eap_ttls               = false
  allow_teap                   = true
  allow_preferred_eap_protocol = false
  eap_tls_l_bit                = false
  allow_weak_ciphers_for_eap   = false
  require_message_auth         = false

  eap_tls_allow_auth_of_expired_certs     = false
  eap_tls_enable_stateless_session_resume = true
  eap_tls_session_ticket_ttl              = 5
  eap_tls_session_ticket_ttl_unit         = "HOURS"
  eap_tls_session_ticket_percentage       = 10

  teap_eap_ms_chap_v2                               = true
  teap_eap_ms_chap_v2_pwd_change                    = true
  teap_eap_ms_chap_v2_pwd_change_retries            = 3
  teap_eap_tls                                      = true
  teap_eap_tls_auth_of_expired_certs                = true
  teap_eap_accept_client_cert_during_tunnel_est     = true
  teap_eap_chaining                                 = true
  teap_downgrade_msk                                = true
  teap_request_basic_pwd_auth                       = true
}

resource "ise_allowed_protocols" "mab_eaptls" {
  name                         = "MAB_EAP-TLS"
  description                  = ""
  process_host_lookup          = true
  allow_pap_ascii              = false
  allow_chap                   = false
  allow_ms_chap_v1             = false
  allow_ms_chap_v2             = false
  allow_eap_md5                = false
  allow_eap_tls                = true
  allow_leap                   = false
  allow_peap                   = false
  allow_eap_fast               = false
  allow_eap_ttls               = false
  allow_teap                   = false
  allow_preferred_eap_protocol = false
  eap_tls_l_bit                = false
  allow_weak_ciphers_for_eap   = false
  require_message_auth         = false

  eap_tls_allow_auth_of_expired_certs     = false
  eap_tls_enable_stateless_session_resume = true
  eap_tls_session_ticket_ttl              = 5
  eap_tls_session_ticket_ttl_unit         = "HOURS"
  eap_tls_session_ticket_percentage       = 10
}

resource "ise_allowed_protocols" "eaptls" {
  name                         = "EAP-TLS"
  description                  = ""
  process_host_lookup          = false
  allow_pap_ascii              = false
  allow_chap                   = false
  allow_ms_chap_v1             = false
  allow_ms_chap_v2             = false
  allow_eap_md5                = false
  allow_eap_tls                = true
  allow_leap                   = false
  allow_peap                   = false
  allow_eap_fast               = false
  allow_eap_ttls               = false
  allow_teap                   = false
  allow_preferred_eap_protocol = false
  eap_tls_l_bit                = false
  allow_weak_ciphers_for_eap   = false
  require_message_auth         = false

  eap_tls_allow_auth_of_expired_certs     = false
  eap_tls_enable_stateless_session_resume = true
  eap_tls_session_ticket_ttl              = 5
  eap_tls_session_ticket_ttl_unit         = "HOURS"
  eap_tls_session_ticket_percentage       = 10
}

## Create a Certificate Authentication Profile (CAP)
## Commented out due to bug ID CSCwe48292

# resource "ise_certificate_authentication_profile" "certprof_ad" {
#   depends_on = [
#     ise_active_directory_join_point.corp_ad
#   ]
# 
#   name                         = "CertProf_AD"
#   description                  = "AD Cert Profile"
#   external_identity_store_name = ise_active_directory_join_point.corp_ad.name
#   allowed_as_user_name         = false
#   certificate_attribute_name   = "SUBJECT_COMMON_NAME"
#   match_mode                   = "RESOLVE_IDENTITY_AMBIGUITY"
#   username_from                = "CERTIFICATE"
# }


## Create an Identity Source Sequence using the CAP and AD Join Point

resource "ise_identity_source_sequence" "iss_ad_cert" {
  name                               = "ISS_AD_Cert"
  description                        = ""
  break_on_store_fail                = false
  certificate_authentication_profile = "Preloaded_Certificate_Profile"
#  certificate_authentication_profile = ise_certificate_authentication_profile.certprof_ad.name
  identity_sources = [
    {
      name = ise_active_directory_join_point.corp_ad.name
      # name  = ise_certificate_authentication_profile.certprof_ad.external_identity_store_name
      order = 1
    }
  ]
}

# Create Network Device Groups for Monitor Mode & Low Impact Mode

resource "ise_network_device_group" "ndg_deployment_stage" {
  description = "Root Deployment Stage NDG"
  name        = "Deployment Stage#Deployment Stage"
  root_group  = "Deployment Stage"
}

resource "ise_network_device_group" "ndg_mm" {
  depends_on = [
    ise_network_device_group.ndg_deployment_stage
  ]
  description = "Monitor Mode NDG"
  name        = "Deployment Stage#Deployment Stage#Monitor Mode"
  root_group  = ise_network_device_group.ndg_deployment_stage.root_group
}

resource "ise_network_device_group" "ndg_lim" {
  depends_on = [
    ise_network_device_group.ndg_deployment_stage,
    ise_network_device_group.ndg_mm
  ]
  description = "Low Impact Mode NDG"
  name        = "Deployment Stage#Deployment Stage#Low Impact Mode"
  root_group  = ise_network_device_group.ndg_deployment_stage.root_group
}

# Create DACLs

resource "ise_downloadable_acl" "mm_dacl_ad_computer" {
  dacl        = "permit ip any any"
  dacl_type   = "IPV4"
  description = ""
  name        = "MM-DACL-AD-Computer"
}

resource "ise_downloadable_acl" "mm_dacl_ad_user" {
  dacl        = "permit ip any any"
  dacl_type   = "IPV4"
  description = ""
  name        = "MM-DACL-AD-User"
}

resource "ise_downloadable_acl" "mm_dacl_default" {
  dacl        = "permit ip any any"
  dacl_type   = "IPV4"
  description = ""
  name        = "MM-DACL-Default"
}

resource "ise_downloadable_acl" "lim_dacl_ad_computer" {
  dacl        = "permit ip any any"
  dacl_type   = "IPV4"
  description = ""
  name        = "LIM-DACL-AD-Computer"
}

resource "ise_downloadable_acl" "lim_dacl_ad_user" {
  dacl        = "permit ip any any"
  dacl_type   = "IPV4"
  description = ""
  name        = "LIM-DACL-AD-User"
}

resource "ise_downloadable_acl" "lim_dacl_default" {
  dacl        = "permit udp any eq bootpc any eq bootps\npermit udp any any eq domain\npermit udp any any eq tftp\ndeny ip any any"
  dacl_type   = "IPV4"
  description = ""
  name        = "LIM-DACL-Default"
}


## Create Authorization Profiles

resource "ise_authorization_profile" "mm_authz_ad_computer" {
  name         = "MM-AuthZ-AD-Computer"
  description  = ""
  access_type  = "ACCESS_ACCEPT"
  profile_name = "Cisco"
  dacl_name    = ise_downloadable_acl.mm_dacl_ad_computer.name
}

resource "ise_authorization_profile" "mm_authz_ad_user" {
  name         = "MM-AuthZ-AD-User"
  description  = ""
  access_type  = "ACCESS_ACCEPT"
  profile_name = "Cisco"
  dacl_name    = ise_downloadable_acl.mm_dacl_ad_user.name
}

resource "ise_authorization_profile" "mm_authz_default" {
  name         = "MM-AuthZ-Default"
  description  = ""
  access_type  = "ACCESS_ACCEPT"
  profile_name = "Cisco"
  dacl_name    = ise_downloadable_acl.mm_dacl_default.name
}

resource "ise_authorization_profile" "lim_authz_ad_computer" {
  name         = "LIM-AuthZ-AD-Computer"
  description  = ""
  access_type  = "ACCESS_ACCEPT"
  profile_name = "Cisco"
  dacl_name    = ise_downloadable_acl.lim_dacl_ad_computer.name
}

resource "ise_authorization_profile" "lim_authz_ad_user" {
  name         = "LIM-AuthZ-AD-User"
  description  = ""
  access_type  = "ACCESS_ACCEPT"
  profile_name = "Cisco"
  dacl_name    = ise_downloadable_acl.lim_dacl_ad_user.name
}

resource "ise_authorization_profile" "lim_authz_default" {
  name         = "LIM-AuthZ-Default"
  description  = ""
  access_type  = "ACCESS_ACCEPT"
  profile_name = "Cisco"
  dacl_name    = ise_downloadable_acl.lim_dacl_default.name
}

resource "ise_authorization_profile" "authz_wireless_ad_computer" {
  name          = "AuthZ-Wireless-AD-Computer"
  description   = ""
  access_type   = "ACCESS_ACCEPT"
  profile_name  = "Cisco"
  airespace_acl = var.wireless_acl_name
}

resource "ise_authorization_profile" "authz_wireless_ad_user" {
  name          = "AuthZ-Wireless-AD-User"
  description   = ""
  access_type   = "ACCESS_ACCEPT"
  profile_name  = "Cisco"
  airespace_acl = var.wireless_acl_name
}
