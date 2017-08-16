# PowerShell script: Report-VMWareVMs
A PowerShell script that collects information about the VMs on VMWare.

You can edit the last lines to export the data in any form you need, by default it doest to GridView.

## Requirements

- Script is desinged to run from your workstation
- [PowerCLI] (https://www.powershellgallery.com/packages/VMware.PowerCLI) must be installed. 

## Usage
1. Open PowerShell ISE
1. Import VMWare Core module with VMWare prefix using this command
    `Import-Module VMware.VimAutomation.Core -Prefix "VMWare"`
   I use this technique to avoid colliding with Hyper-V cmdlets as they share the same names.
2. Connect to vSphere using this command,
    `Connect-VMWareVIServer -Server <vSphereServerName> -Credential (Get-Credential)`
4. Open the script and run it.
5. Review the GridViews and export again to CSV if needed.
