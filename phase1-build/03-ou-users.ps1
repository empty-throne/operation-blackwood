# 03-ou-users.ps1
$root = "DC=BLACKWOOD,DC=local"

# OUs
New-ADOrganizationalUnit -Name "_BLACKWOOD" -Path $root
New-ADOrganizationalUnit -Name "Computers" -Path "OU=_BLACKWOOD,$root"
New-ADOrganizationalUnit -Name "Workstations" -Path "OU=Computers,OU=_BLACKWOOD,$root"
New-ADOrganizationalUnit -Name "Servers" -Path "OU=Computers,OU=_BLACKWOOD,$root"
New-ADOrganizationalUnit -Name "Users" -Path "OU=_BLACKWOOD,$root"
New-ADOrganizationalUnit -Name "IT" -Path "OU=Users,OU=_BLACKWOOD,$root"
New-ADOrganizationalUnit -Name "HR" -Path "OU=Users,OU=_BLACKWOOD,$root"
New-ADOrganizationalUnit -Name "Finance" -Path "OU=Users,OU=_BLACKWOOD,$root"
New-ADOrganizationalUnit -Name "Groups" -Path "OU=_BLACKWOOD,$root"
New-ADOrganizationalUnit -Name "Service Accounts" -Path "OU=_BLACKWOOD,$root"

# Users
New-ADUser -Name "John Smith" -SamAccountName "jsmith" `
  -UserPrincipalName "jsmith@BLACKWOOD.local" `
  -Path "OU=HR,OU=Users,OU=_BLACKWOOD,DC=BLACKWOOD,DC=local" `
  -AccountPassword (ConvertTo-SecureString "Password123!" -AsPlainText -Force) `
  -Enabled $true -PasswordNeverExpires $true

New-ADUser -Name "Alice Turner" -SamAccountName "aturner" `
  -UserPrincipalName "aturner@BLACKWOOD.local" `
  -Path "OU=IT,OU=Users,OU=_BLACKWOOD,DC=BLACKWOOD,DC=local" `
  -AccountPassword (ConvertTo-SecureString "Summer2024!" -AsPlainText -Force) `
  -Enabled $true -PasswordNeverExpires $true

New-ADUser -Name "Bob Carter" -SamAccountName "bcarter" `
  -UserPrincipalName "bcarter@BLACKWOOD.local" `
  -Path "OU=Finance,OU=Users,OU=_BLACKWOOD,DC=BLACKWOOD,DC=local" `
  -AccountPassword (ConvertTo-SecureString "Welcome1!" -AsPlainText -Force) `
  -Enabled $true -PasswordNeverExpires $true

New-ADUser -Name "SVC-Backup" -SamAccountName "svc-backup" `
  -UserPrincipalName "svc-backup@BLACKWOOD.local" `
  -Path "OU=Service Accounts,OU=_BLACKWOOD,DC=BLACKWOOD,DC=local" `
  -AccountPassword (ConvertTo-SecureString "Backup`$vc1!" -AsPlainText -Force) `
  -Enabled $true -PasswordNeverExpires $true

# Domain Admin
Add-ADGroupMember -Identity "Domain Admins" -Members "aturner"

# SPN
setspn -A HTTP/backup.BLACKWOOD.local svc-backup

Write-Host "Users and OUs created successfully." -ForegroundColor Green
