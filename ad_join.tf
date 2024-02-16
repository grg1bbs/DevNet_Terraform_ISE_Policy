## Create Active Directory Join Point

resource "ise_active_directory_join_point" "corp_ad" {
  name            = var.join_point_name
  description     = ""
  ad_scopes_names = "Default_Scope"
  domain          = var.domain_name

}

## Join the node(s) to the AD Domain

resource "ise_active_directory_join_domain_with_all_nodes" "corp_ad" {
  join_point_id = ise_active_directory_join_point.corp_ad.id
  additional_data = [
    {
      name  = "username"
      value = var.ad_admin_name
    },
    {
      name  = "password"
      value = var.ad_admin_password
    }
  ]
}

## Search AD domain join point for groups to capture the name, SID, and type values

data "ise_active_directory_groups_by_domain" "domain_computers" {
  depends_on = [
    ise_active_directory_join_domain_with_all_nodes.corp_ad
  ]
  join_point_id = ise_active_directory_join_point.corp_ad.id
  domain        = var.domain_name
  filter        = var.ad_group_domain_computers_filter
}

data "ise_active_directory_groups_by_domain" "domain_users" {
  depends_on = [
    ise_active_directory_join_domain_with_all_nodes.corp_ad
  ]
  join_point_id = ise_active_directory_join_point.corp_ad.id
  domain        = var.domain_name
  filter        = var.ad_group_domain_users_filter
}

data "ise_active_directory_groups_by_domain" "net_admin" {
  depends_on = [
    ise_active_directory_join_domain_with_all_nodes.corp_ad
  ]
  join_point_id = ise_active_directory_join_point.corp_ad.id
  domain        = var.domain_name
  filter        = var.ad_group_net_admin_filter
}

data "ise_active_directory_groups_by_domain" "net_monitor" {
  depends_on = [
    ise_active_directory_join_domain_with_all_nodes.corp_ad
  ]
  join_point_id = ise_active_directory_join_point.corp_ad.id
  domain        = var.domain_name
  filter        = var.ad_group_net_monitor_filter
}

## Add AD Groups

resource "ise_active_directory_add_groups" "ad_domain_groups" {
  join_point_id              = ise_active_directory_join_point.corp_ad.id
  name                       = ise_active_directory_join_point.corp_ad.name
  description                = ise_active_directory_join_point.corp_ad.description
  domain                     = ise_active_directory_join_point.corp_ad.domain
  ad_scopes_names            = ise_active_directory_join_point.corp_ad.ad_scopes_names
  enable_domain_allowed_list = ise_active_directory_join_point.corp_ad.enable_domain_allowed_list
  groups = [
    {
      "name" : data.ise_active_directory_groups_by_domain.domain_computers.groups[0].name
      "sid" : data.ise_active_directory_groups_by_domain.domain_computers.groups[0].sid
      "type" : data.ise_active_directory_groups_by_domain.domain_computers.groups[0].type
    },
    {
      "name" : data.ise_active_directory_groups_by_domain.domain_users.groups[0].name
      "sid" : data.ise_active_directory_groups_by_domain.domain_users.groups[0].sid
      "type" : data.ise_active_directory_groups_by_domain.domain_users.groups[0].type

    },
    {
      "name" : data.ise_active_directory_groups_by_domain.net_admin.groups[0].name
      "sid" : data.ise_active_directory_groups_by_domain.net_admin.groups[0].sid
      "type" : data.ise_active_directory_groups_by_domain.net_admin.groups[0].type

    },
    {
      "name" : data.ise_active_directory_groups_by_domain.net_monitor.groups[0].name
      "sid" : data.ise_active_directory_groups_by_domain.net_monitor.groups[0].sid
      "type" : data.ise_active_directory_groups_by_domain.net_monitor.groups[0].type

    }
  ]
}

# Wait 5 seconds to mitigate API race conditions
resource "time_sleep" "ad_group_wait" {
  depends_on = [ise_active_directory_add_groups.ad_domain_groups]
  create_duration  = "5s"
  destroy_duration = "5s"
}
