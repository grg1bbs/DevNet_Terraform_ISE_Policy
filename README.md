
# DevNet_Terraform_ISE_Policy
Terraform code for creating Network Access and Device Admin Policy Sets in Cisco Identity Services Engine (ISE) 3.2 using the CiscoDevNet Terraform provider.
This code is intended to build policy that is common amongst customer ISE deployments. Due to the way the ISE APIs are designed and the inherent limitations, the policies deployed by this code are intended to provide a starting point for a much broader configuration workflow. The Terraform state will likely provide little value for ongoing maintenance and management of the ISE Policies due to current ISE API caveats and limitations.

Separate files were used purposely to separate out the various policy elements in an attempt to make it easier to read and modify the resources being created. If a more monolithic approach is desired, the code can be collapsed into fewer files.

This code was validated using the following:
 - Cisco ISE 3.2 patch 5
 - Terraform version: 1.7.5
 - CiscoDevNet Terraform provider version: 0.1.14
 
The CiscoDevNet ISE Terraform Provider documentation can be found here:
https://registry.terraform.io/providers/CiscoDevNet/ise/latest/docs

## ISE Pre-requisites
The following ISE configurations are required prior to running this code:

1. An administrator account with the 'ERS Admin' role
2. An Active Directory admin username/password with the permissions necessary to join the ISE nodes to the AD domain
3. The name of the Airespace Access List configured on the WLC to permit access for authorized Wireless sessions

## Policies and Policy Elements created
The following Policy Elements and Policy Sets are created by this code:

### Active Directory
 - AD Join Point created
 - Perform AD join operation for all nodes
 - Search the domain and add the following AD Groups
   - Domain Users (Used by Network Access policies)
   - Domain Computers (Used by Network Access policies)
   - Net Admin (Used by Device Admin policies)
   - Net Monitor (Used by Device Admin policies)
  
### Network Access Policy Elements

 - Allowed Protocols list named 'MAB_Dot1x' with the following protocols enabled:
   - Process Host Lookup (MAB)
   - EAP-TLS
   - TEAP (with EAP Chaining)
 - Allowed Protocols list named 'EAP-TLS' with the following protocols enabled:
   - EAP-TLS
 - Certificate Authentication Profile (for EAP-TLS and TEAP[EAP-TLS]) :warning: See the Caveats & Limitations section below
 - Identity Source Sequence with CAP & AD
 - Network Device Group (NDG) structure for Deployment Stage (Monitor Mode & Low Impact Mode)
 - Downloadable ACLs and AuthZ Profiles
   - Permissive DACLs (permit ip any any) except for LIM Default (permits DHCP, DNS, and TFTP only)
 - TrustSec Security Group Tag (SGT) for 'Corporate Users'
  
### Network Access Policy Sets

#### Wired MM
 - AuthC Policies
   - Dot1x TEAP
   - Dot1x EAP-TLS
   - MAB
 - AuthZ Policies
   - (TEAP) AD User EAP Chained + Corporate Users SGT
   - (TEAP) AD Computer + Corporate Users SGT
   - (EAP-TLS) AD User + Corporate Users SGT
   - (EAP-TLS) AD Computer + Corporate Users SGT
   - Default (updated AuthZ Profile)

#### Wired LIM
 - AuthC Policies
   - Dot1x TEAP
   - Dot1x EAP-TLS
   - MAB
 - AuthZ Policies
   - (TEAP) AD User EAP Chained + Corporate Users SGT
   - (TEAP) AD Computer + Corporate Users SGT
   - (EAP-TLS) AD User + Corporate Users SGT
   - (EAP-TLS) AD Computer + Corporate Users SGT
   - Default (updated AuthZ Profile)
   
#### Wireless Secure
 - AuthC Policy
   - Dot1x TEAP
   - Dot1x EAP-TLS
 - AuthZ Policies
   - (TEAP) AD User EAP Chained + Corporate Users SGT
   - (TEAP) AD Computer + Corporate Users SGT
   - (EAP-TLS) AD User + Corporate Users SGT
   - (EAP-TLS) AD Computer + Corporate Users SGT

## Device Admin Policy Elements

 - Allowed Protocols list named 'PAP' with the following protocols enabled:
   - PAP/ASCII
 - Network Device Group (NDG) structure for WLC OS Type (AirOS & IOS-XE)
 - Network Device Groups (NDGs) for Cisco Router, Cisco Switch, and Cisco WLC
 - TACACS Command Sets:
   - Permit All Commands
   - Permit Show Commands (permit show *)
 - TACACS Profiles:
   - Privilege 10 access for IOS/IOS-XE
   - Privilege 15 access for IOS/IOS-XE
  
### Device Admin Policy Sets

Routers & Switches
 - AuthC Policies
   - PAP
 - AuthZ Policies
   - Router Switch ReadOnly
   - Router Switch Admin

Wireless Controllers
 - AuthC Policies
   - PAP
 - AuthZ Policies
   - AireOS WLC Monitor
   - AireOS WLC Admin
   - IOS-XE WLC Monitor
   - IOS-XE WLC Admin

## Network Access Policy Set Configuration Example
<img width="1323" alt="DevNet_TF_ISE_Policy_Sets" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/f9fff675-3090-48db-a9d1-fac6e0480cfe">

### Network Access - Wired Monitor Mode Policy Set Example
<img width="1473" alt="DevNet_TF_ISE_MM_AuthC_Policy" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/c3b8802d-3d35-497b-be56-13e49a30c080">
<img width="1473" alt="DevNet_TF_ISE_MM_AuthC_Policy_Default" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/2e00d64d-b0c1-40da-9aa3-e9c7c629e57a">
<img width="1473" alt="DevNet_TF_ISE_MM_AuthZ_Policy" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/0579f612-0f74-4b35-bbca-6c482d5e926a">
<img width="1419" alt="Screenshot 2024-02-16 at 3 54 19 pm" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/a60164b9-aa06-4c5c-bd33-2b4585ede3f7">


### Network Access - Corp Wireless Policy Set Example
<img width="1473" alt="DevNet_TF_ISE_Wireless_AuthC_Policy" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/2a973f03-4a66-45fa-846c-0f01d80512dd">
<img width="1473" alt="DevNet_TF_ISE_Wireless_AuthZ_Policy" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/86137e91-2c58-4aca-9a20-3b614ccb226f">
<img width="1473" alt="DevNet_TF_ISE_Wireless_AuthZ_Policy_Default" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/92ee2046-f291-4cf1-9a18-e086dcadfbd6">

## Device Admin Policy Set Configuration Example
<img width="1342" alt="DevNet_TF_ISE_DevAdmin_Policy_Sets" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/ab9b6e7c-f7b6-43f9-913a-6513a3259fab">

## Device Admin - Routers & Switches Policy Set Example
<img width="1407" alt="DevNet_TF_ISE_RouterSwitch_AuthC_Policy" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/8d257c2a-e80c-4295-8515-55a14a18b31f">
<img width="1407" alt="DevNet_TF_ISE_RouterSwitch_AuthZ_Policy" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/dcf5462e-75f3-4bb2-af27-362d7177ecd9">

## Device Admin - WLC Policy Set Example
<img width="1407" alt="DevNet_TF_ISE_WLC_AuthC_Policy" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/61d829af-2317-4e2e-b1f6-b1e9a66a36ad">
<img width="1418" alt="DevNet_TF_ISE_WLC_AuthZ_Policy" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/ddbb942b-181e-471e-936e-7092720e2b81">

### Caveats & Limitations

An error will be seen at the initial 'terraform destroy' due to a current limitation in the ISE APIs. At this time, there is no API DELETE operation for the Certificate Authentication Profile (CAP) resource. Since the AD Join Point is referenced in the CAP resource, the destroy will throw an error due to the inability to delete the Join Point. At this time the only workaround is to delete the Certificate Authentication Profile from the GUI, then run the 'terraform destroy' a second time. This will delete the remaining resources. The following bug has been raised to request the API DELETE operation be provided to address this issue.

https://bst.cloudapps.cisco.com/bugsearch/bug/CSCwe48292

## Quick Start
1. Clone this repository:  

    ```bash
    git clone https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy
    ```
 
2. Edit the 'variables.tf' file to suit your environment (Active Directory user/password/domain, Corporate SSID name, etc.)

3. Edit the 'terraform.tf' file with the username, password, and base URL values required for your ISE Primary Admin Node (PAN)

4. Initialise, Plan, and Apply the terraform run

    ```bash
    terraform init
    
    terraform plan
    
    terraform apply
    ```

### Resulting resources
Unless any errors are found, after the resource build is complete, the resulting status should be:

```diff
+ Apply complete! Resources: 72 added, 0 changed, 0 destroyed.
```

If you check the terraform state, you should see the following resources:
 
```bash
❯ terraform state list
data.ise_active_directory_groups_by_domain.domain_computers
data.ise_active_directory_groups_by_domain.domain_users
data.ise_active_directory_groups_by_domain.net_admin
data.ise_active_directory_groups_by_domain.net_monitor
data.ise_network_access_authorization_rule.lim_authz_default
data.ise_network_access_authorization_rule.mm_authz_default
data.ise_network_access_condition.wired_dot1x
data.ise_network_access_condition.wired_mab
data.ise_network_access_condition.wireless_dot1x
data.ise_network_access_policy_set.ps_wired_lim
data.ise_network_access_policy_set.ps_wired_mm
data.ise_tacacs_profile.wlc_all
data.ise_tacacs_profile.wlc_monitor
ise_active_directory_add_groups.ad_domain_groups
ise_active_directory_join_domain_with_all_nodes.corp_ad
ise_active_directory_join_point.corp_ad
ise_allowed_protocols.eaptls
ise_allowed_protocols.mab_dot1x
ise_allowed_protocols_tacacs.pap_ascii
ise_authorization_profile.authz_wireless_ad_computer
ise_authorization_profile.authz_wireless_ad_user
ise_authorization_profile.lim_authz_ad_computer
ise_authorization_profile.lim_authz_ad_user
ise_authorization_profile.lim_authz_default
ise_authorization_profile.mm_authz_ad_computer
ise_authorization_profile.mm_authz_ad_user
ise_authorization_profile.mm_authz_default
ise_certificate_authentication_profile.certprof_ad
ise_device_admin_authentication_rule.authc_router_switch_pap
ise_device_admin_authentication_rule.authc_wlc_pap
ise_device_admin_authorization_rule.authz_aireos_wlc_admin
ise_device_admin_authorization_rule.authz_aireos_wlc_readonly
ise_device_admin_authorization_rule.authz_iosxe_wlc_admin
ise_device_admin_authorization_rule.authz_iosxe_wlc_readonly
ise_device_admin_authorization_rule.authz_router_switch_admin
ise_device_admin_authorization_rule.authz_router_switch_readonly
ise_device_admin_policy_set.ps_router_switch
ise_device_admin_policy_set.ps_wlc
ise_downloadable_acl.lim_dacl_ad_computer
ise_downloadable_acl.lim_dacl_ad_user
ise_downloadable_acl.lim_dacl_default
ise_downloadable_acl.mm_dacl_ad_computer
ise_downloadable_acl.mm_dacl_ad_user
ise_downloadable_acl.mm_dacl_default
ise_identity_source_sequence.iss_ad_cert
ise_network_access_authentication_rule.authc_wireless_eaptls
ise_network_access_authentication_rule.authc_wireless_teap
ise_network_access_authentication_rule.lim_authc_eaptls
ise_network_access_authentication_rule.lim_authc_mab
ise_network_access_authentication_rule.lim_authc_teap
ise_network_access_authentication_rule.mm_authc_eaptls
ise_network_access_authentication_rule.mm_authc_mab
ise_network_access_authentication_rule.mm_authc_teap
ise_network_access_authorization_rule.authz_wireless_ad_computer_eaptls
ise_network_access_authorization_rule.authz_wireless_ad_computer_teap
ise_network_access_authorization_rule.authz_wireless_ad_user_eaptls
ise_network_access_authorization_rule.authz_wireless_ad_user_teap
ise_network_access_authorization_rule.lim_authz_ad_computer_eaptls
ise_network_access_authorization_rule.lim_authz_ad_computer_teap
ise_network_access_authorization_rule.lim_authz_ad_user_eaptls
ise_network_access_authorization_rule.lim_authz_ad_user_teap
ise_network_access_authorization_rule.lim_authz_default
ise_network_access_authorization_rule.mm_authz_ad_computer_eaptls
ise_network_access_authorization_rule.mm_authz_ad_computer_teap
ise_network_access_authorization_rule.mm_authz_ad_user_eaptls
ise_network_access_authorization_rule.mm_authz_ad_user_teap
ise_network_access_authorization_rule.mm_authz_default
ise_network_access_policy_set.ps_wired_lim
ise_network_access_policy_set.ps_wired_mm
ise_network_access_policy_set.ps_wireless_secure
ise_network_device_group.ndg_cisco_router
ise_network_device_group.ndg_cisco_switch
ise_network_device_group.ndg_cisco_wlc
ise_network_device_group.ndg_deployment_stage
ise_network_device_group.ndg_lim
ise_network_device_group.ndg_mm
ise_network_device_group.ndg_wlc_aireos
ise_network_device_group.ndg_wlc_iosxe
ise_network_device_group.ndg_wlc_os_type
ise_tacacs_command_set.permit_all_commands
ise_tacacs_command_set.permit_show_commands
ise_tacacs_profile.ios_admin_priv10
ise_tacacs_profile.ios_admin_priv15
ise_trustsec_security_group.sgt_corp_user
time_sleep.ad_group_wait
```

### Teardown
To revert all of the configuration that was applied, use 'terraform destroy' and the dependency mappings should ensure everything is destroyed in the correct order.

```bash
> terraform destroy
```
