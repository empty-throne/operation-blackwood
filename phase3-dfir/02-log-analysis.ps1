# 02-log-analysis.ps1
# Detect password spray
Get-WinEvent -Path "C:\Evidence\DC01-Security.evtx" |
  Where-Object { $_.Id -eq 4625 } |
  Select-Object TimeCreated,
    @{N='SourceIP';E={$_.Properties[19].Value}},
    @{N='TargetUser';E={$_.Properties[5].Value}} |
  Group-Object SourceIP |
  Where-Object Count -gt 5 |
  Sort-Object Count -Descending

# Detect PTH - filter aturner NTLM auth
Get-WinEvent -Path "C:\Evidence\DC01-Security.evtx" |
  Where-Object { $_.Id -eq 4776 } |
  Select-Object TimeCreated,
    @{N='Account';E={$_.Properties[1].Value}},
    @{N='Workstation';E={$_.Properties[2].Value}},
    @{N='ErrorCode';E={$_.Properties[3].Value}} |
  Where-Object Account -eq "aturner"
