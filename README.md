:warning: **This code is still in development** :warning:

# DevNet_Terraform_ISE_Policy
Terraform code for creating Network Access and Device Admin Policy Sets in Cisco Identity Services Engine (ISE) 3.2 using the CiscoDevNet Terraform provider.
This code is intended to build policy that is common amongst customer ISE deployments. Due to the way the ISE APIs are designed and the inherent limitations, the policies deployed by this code are intended to provide a starting point for a much broader configuration workflow. The Terraform state will likely provide little value for ongoing maintenance and management of the ISE Policies due to current ISE API caveats and limitations.

Separate files were used purposely to separate out the various policy elements in an attempt to make it easier to read and modify the resources being created. If a more monolithic approach is desired, the code can be collapsed into fewer files.

This code was validated using the following:
 - Cisco ISE 3.2 patch 4
 - Terraform version: 1.6.6
 - CiscoDevNet Terraform provider version: 0.1.12
 
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
 - Certificate Authentication Profile (for EAP-TLS and TEAP[EAP-TLS]) :warning: Using default CAP due to bug
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
   - Default (updated AuthZ Profile) :warning: Pending Issue with Import

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
   - Default (updated AuthZ Profile) :warning: Pending Issue with Import
   
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
<img width="1473" alt="DevNet_TF_ISE_MM_AuthZ_Policy_DefaultDeny" src="https://github.com/grg1bbs/DevNet_Terraform_ISE_Policy/assets/103554967/5e81ea05-5fc7-4d70-ba2b-858ee454c093">

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

This code currently uses only the default Certificate Authentication Profile (CAP) due to the following known bug:
https://bst.cloudapps.cisco.com/bugsearch/bug/CSCwe48292




