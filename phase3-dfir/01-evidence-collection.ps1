# 01-evidence-collection.ps1
# Create evidence directory
New-Item -ItemType Directory -Path "C:\Evidence" -Force

# Export Security event log
wevtutil epl Security C:\Evidence\DC01-Security.evtx

# Export key auth events to CSV
Get-WinEvent -FilterHashtable @{
  LogName   = 'Security'
  Id        = 4625,4624,4776,4648,4672
  StartTime = (Get-Date).AddDays(-1)
} | Export-Csv C:\Evidence\auth-events.csv -NoTypeInformation

Write-Host "Evidence collected." -ForegroundColor Green
