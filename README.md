# PowerShell script: Report-VMWareVMs
A PowerShell script that collects information about the VMs on VMWare.

You can edit the last line to export the data in any form you need, by default it doest to GridView.

## Requirements

- PowerCLI must be installed.
- I prefix all VMWare cmdlets with 'VMWare' to avoid collision with Hyper-V cmdlets. So use the following command when importing VMWare modules: `Import-Module VMware.VimAutomation.Cis.Core -Prefix "VMWare"`
- You must be connected to VSphere using the Connect-VMWareVIServer cmdlet (notice the VMWare prefix)


