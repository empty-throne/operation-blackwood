# 02-domain-setup.ps1
# Install AD DS and promote to Domain Controller
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Install-ADDSForest `
  -DomainName "BLACKWOOD.local" `
  -DomainNetbiosName "BLACKWOOD" `
  -ForestMode "WinThreshold" `
  -DomainMode "WinThreshold" `
  -InstallDns:$true `
  -Force:$true
