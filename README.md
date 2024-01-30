# DevNet_Terraform_ISE_Policy
Terraform code for creating Network Access and Device Admin Policy Sets in Cisco Identity Services Engine (ISE) 3.2
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

 - Allowed Protocols list named 'MAB_EAP-TLS' with the following protocols enabled:
   - Process Host Lookup (MAB)
   - EAP-TLS
 - Allowed Protocols list named 'EAP-TLS' with the following protocols enabled:
   - EAP-TLS
 - Certificate Authentication Profile (for EAP-TLS) :warning: Using default CAP due to bug
 - Identity Source Sequence with CAP & AD
 - Network Device Group (NDG) structure for Deployment Stage (Monitor Mode & Low Impact Mode)
 - Downloadable ACLs and AuthZ Profiles
   - Permissive DACLs (permit ip any any) except for LIM Default (permits DHCP, DNS, and TFTP only)
 - TrustSec Security Group Tag (SGT) for 'Corporate Users'
  
### Network Access Policy Sets

Wired_MM
 - AuthC Policies
   - Dot1x EAP-TLS
   - MAB
 - AuthZ Policies
   - AD User + Corporate Users SGT
   - AD Computer + Corporate Users SGT
   - Default (updated AuthZ Profile) :warning: Pending Issue with Import

Wired_LIM
 - AuthC Policies
   - Dot1x EAP-TLS
   - MAB
 - AuthZ Policies
   - AD User + Corporate Users SGT
   - AD Computer + Corporate Users SGT
   - Default (updated AuthZ Profile) :warning: Pending Issue with Import
   
Wireless_Secure
 - AuthC Policy
   - Dot1x EAP-TLS
 - AuthZ Policies
   - AD User + Corporate Users SGT
   - AD Computer + Corporate Users SGT

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
