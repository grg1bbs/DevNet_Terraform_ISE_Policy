## Active Directory variables
## The AD admin username/password variables can also be referenced by standard options like local environment variables, *.tfvars file, etc.

variable "ad_admin_name" {
  default     = "<admin user>"
  description = "AD Domain username used to join ISE to the domain"
  sensitive   = true
}

variable "ad_admin_password" {
  default     = "<admin password>"
  description = "AD Domain password used to join ISE to the domain"
  sensitive   = true
}

variable "domain_name" {
  default     = "trappedunderise.com"
  description = "AD Domain name used when joining ISE to the domain"
}

variable "join_point_name" {
  default     = "ISELAB_AD"
  description = "Name defined for the Active Directory Join Point in ISE"
  sensitive   = true
}

## AD Groups used in Network Access policies

variable "ad_group_domain_users_filter" {
  default     = "*Domain Users"
  description = "Filter string for Domain Users AD Group"
}

variable "ad_group_domain_computers_filter" {
  default     = "*Domain Computers"
  description = "Filter string for Domain Computers AD Group"
}

## AD Groups used in Device Admin policies

variable "ad_group_net_admin_filter" {
  default     = "*Net Admin"
  description = "Filter string for Net Admin AD Group (Device Admin Read-Write)"
}

variable "ad_group_net_monitor_filter" {
  default     = "*Net Monitor"
  description = "Filter string for Net Monitor AD Group (Device Admin Read-Only)"
}

## Variables used in Network Access policies

variable "ps_wired_mm_name" {
  default     = "Wired MM"
  description = "Name defined for the Wired Monitor Mode Policy Set"
}

variable "ps_wired_lim_name" {
  default     = "Wired LIM"
  description = "Name defined for the Wired Low Impact Mode Policy Set"
}

variable "authc_policy_eaptls" {
  default     = "Dot1x EAP-TLS"
  description = "Name defined for the 802.1x EAP-TLS Authentication Policy for all Policy Sets"
}

variable "authz_policy_ad_user" {
  default     = "AD User"
  description = "Name defined for the AD User Authorization Policy for all Policy Sets"
}

variable "authz_policy_ad_computer" {
  default     = "AD Computer"
  description = "Name defined for the AD Computer Authorization Policy for all Policy Sets"
}

variable "authc_policy_mab" {
  default     = "MAB"
  description = "Name defined for the MAB Authentication Policy for the Wired Policy Sets"
}

variable "corp_wireless_ssid" {
  default     = ":iselabemp"
  description = "Name of the Corporate secure SSID, including the preceding colon (:) used as a matching condtion for the Corp Wireless Policy Set"
}

variable "ps_corp_wireless_name" {
  default     = "Wireless_Secure"
  description = "Name defined for the Corporate Wireless Policy Set"
}

variable "wireless_acl_name" {
  default     = "ACL_ALLOW_ALL"
  description = "Airespace ACL name defined in the Wireless Authorization Profiles; must be pre-configured on the WLC"
}

## Variables used in Cisco TrustSec (CTS) / Group Policy elements

variable "sgt_corp_user" {
  default     = "SG_Corp_User"
  description = "Security Group name for Corporate Users"
}

## Variables used in Device Admin Policy elements

# variable "ad_group_net_readonly" {
#   default     = "trappedunderise.com/Users/Net Monitor"
#   description = "AD Group for Network Read Only admins"
# }
# 
# variable "ad_group_net_admin" {
#   default     = "trappedunderise.com/Users/Net Admin"
#   description = "AD Group for Network Read Only admins"
# }
